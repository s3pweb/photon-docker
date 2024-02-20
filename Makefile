all: build

.PHONY: build

build: Dockerfile
	@docker build -t s3pweb/photon-geocoder:$(shell grep 'ENV PHOTON_VERSION' $<|cut -d'=' -f2) -f $< .

.PHONY: push
push: Dockerfile build
	@docker push s3pweb/photon-geocoder:$(shell grep 'ENV PHOTON_VERSION' $<|cut -d'=' -f2)
