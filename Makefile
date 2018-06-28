BIN=prowler
IMAGE=unchartedsky/$(BIN)

image:
	docker build -t $(IMAGE):latest .

deploy: image
	docker push $(IMAGE):latest
