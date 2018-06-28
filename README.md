[![Docker Stars](https://img.shields.io/docker/stars/_/ubuntu.svg)](https://hub.docker.com/r/unchartedsky/prowler/)

# Prowler on Kubernetes example

[toniblyx/prowler](https://github.com/toniblyx/prowler) is:

> Tool based on AWS-CLI commands for AWS account security assessment and hardening, following guidelines of the [CIS Amazon Web Services Foundations Benchmark 1.1](https://d0.awsstatic.com/whitepapers/compliance/AWS_CIS_Foundations_Benchmark.pdf)
> 
> ![](https://cloud.githubusercontent.com/assets/3985464/18489640/50fe6824-79cc-11e6-8a9c-e788b88a8a6b.png)

The motivation is that we want to get Prowler reports on regular basis without human effort. So I made it.

## Step by step

First, create IAM role `Prowler`:

``` bash
aws iam create-role --role-name Prowler --assume-role-policy-document file://policy/prowler-trustpolicy.json
aws iam put-role-policy --role-name Prowler --policy-name Prowler --policy-document file://policy/prowler-policy.json
aws iam attach-role-policy --role-name Prowler --policy-arn arn:aws:iam::aws:policy/SecurityAudit
```

Now you are ready to run the cron job onto K8s cluster. With this example, you will get PDF report files through Slack channel every Sunday:

``` yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prowler-config
data:    
  .slackcat: |
    default_team = "TheTeam"
    default_channel = "YOUR_DEFAULT_SLACK_CHANNEL"

    [teams]
      TheTeam = "YOUR_SLACK_TOKEN"

  run.sh: |
    #!/bin/bash -ex
    FILENAME_SUFFIX="$(date -I)"

    mkdir -p "${RESULT_DIR}"
    ./prowler | tee "${RESULT_DIR}/report-${FILENAME_SUFFIX}.txt" | ansi2html -la | tee "${RESULT_DIR}/report-${FILENAME_SUFFIX}.html"
    cp -f "${RESULT_DIR}/report-${FILENAME_SUFFIX}.txt" "${RESULT_DIR}/report-last.txt"
    cp -f "${RESULT_DIR}/report-${FILENAME_SUFFIX}.html" "${RESULT_DIR}/report-last.html"
    xvfb-run /usr/bin/wkhtmltopdf "${RESULT_DIR}/report-${FILENAME_SUFFIX}.html" "${RESULT_DIR}/report-${FILENAME_SUFFIX}.pdf"
    slackcat "${RESULT_DIR}/report-${FILENAME_SUFFIX}.txt"
    slackcat "${RESULT_DIR}/report-${FILENAME_SUFFIX}.pdf"

---

apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: prowler
  labels:
    app: prowler
spec:
  # See https://crontab.guru/#0_3_*_*_0
  schedule: "0 3 * * 0"
  jobTemplate:
    spec:
      template:
        metadata:
          annotations:
            iam.amazonaws.com/role: arn:aws:iam::1234567890:role/Prowler
          labels:
            app: prowler
        spec:
          containers:
          - name: prowler
            image: unchartedsky/prowler:latest
            command:
            - ./run.sh
            env:
            - name: RESULT_DIR
              value: /tmp/result
            resources:
              requests:
                cpu: "4000m"
                memory: 4000Mi
              limits:
                cpu: "4000m"
                memory: 4000Mi
            volumeMounts:
            - name: conf-d
              mountPath: /root/.slackcat
              subPath: .slackcat
              readOnly: true
            - name: script-d
              mountPath: /prowler/run.sh
              subPath: run.sh
              readOnly: true
          volumes:
          - name: conf-d
            projected:
              sources:
              - configMap:
                  name: prowler-config
                  items:
                  - key: .slackcat
                    path: .slackcat
          - name: script-d
            projected:
              defaultMode: 500
              sources:
              - configMap:
                  name: prowler-config
                  items:
                  - key: run.sh
                    path: run.sh
          restartPolicy: Never
  successfulJobsHistoryLimit: 10
  failedJobsHistoryLimit: 10 
```

## Thanks to 

- [ralphbean/ansi2html](https://github.com/ralphbean/ansi2html) convert text with ansi color codes to HTML.
- [wkhtmltopdf](https://wkhtmltopdf.org/) is open source (LGPLv3) command line tools to render HTML into PDF and various image formats using the Qt WebKit rendering engine.
- [bcicen/slackcat](https://github.com/bcicen) is a CLI utility to post files and command output to slack.
- [ jtblin/kube2iam](https://github.com/jtblin) provides different AWS IAM roles for pods running on Kubernetes 

## TODO

- [ ] Generate the diff between a previous report and a new one using [JoshData/pdf-diff](https://github.com/JoshData/pdf-diff).
