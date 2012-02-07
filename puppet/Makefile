PROJECT = collabograte-puppet
rpmversion = $(shell perl -ne '/^Version: (.*)/ and print $$1' $(PROJECT).spec)

rpm:
	rm -rf /tmp/$(PROJECT)-$(rpmversion){,.tar.gz}
	tar cf - . | (mkdir /tmp/$(PROJECT)-$(rpmversion); cd /tmp/$(PROJECT)-$(rpmversion); tar xf -)
	tar -C /tmp -czf /tmp/$(PROJECT)-$(rpmversion).tar.gz $(PROJECT)-$(rpmversion)
	rpmbuild -ta /tmp/$(PROJECT)-$(rpmversion).tar.gz
