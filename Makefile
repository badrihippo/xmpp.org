PY=python3
PIP=pip3
HUGO=hugo

BASEDIR=$(CURDIR)
INPUTDIR=$(BASEDIR)/content
OUTPUTDIR=$(BASEDIR)/public
TOOLSDIR=$(BASEDIR)/tools

FTP_HOST=localhost
FTP_USER=anonymous
FTP_TARGET_DIR=/

SSH_HOST=localhost
SSH_PORT=22
SSH_USER=root
SSH_TARGET_DIR=/var/www

help:
	@echo 'Makefile for a hugo web site                                           '
	@echo '                                                                       '
	@echo 'Usage:                                                                 '
	@echo '   make html                        (re)generate the web site          '
	@echo '   make clean                       remove the generated files         '
	@echo '   make publish                     generate using production settings '
	@echo '   make serve                       serve site at http://localhost:1313'
	@echo '   make prepare_docker              prepare site for serving via docker'
	@echo '   make ssh_upload                  upload the web site via SSH        '
	@echo '   make rsync_upload                upload the web site via rsync+ssh  '
	@echo '   make ftp_upload                  upload the web site via FTP        '
	@echo '                                                                       '

html:
	$(HUGO)

clean:
	[ ! -d $(OUTPUTDIR) ] || rm -rf $(OUTPUTDIR)

serve:
	$(PIP) install --upgrade -r $(TOOLSDIR)/requirements.txt
	$(PY) $(TOOLSDIR)/prepare_xep_list.py
	$(PY) $(TOOLSDIR)/prepare_rfc_list.py
	$(PY) $(TOOLSDIR)/prepare_software_list.py
	$(PY) $(TOOLSDIR)/prepare_compliance.py
	$(HUGO) version
	$(HUGO) server --bind=0.0.0.0 --baseURL="http://localhost/" --buildFuture

publish:
	$(PIP) install --upgrade -r $(TOOLSDIR)/requirements.txt
	$(PY) $(TOOLSDIR)/prepare_xep_list.py
	$(PY) $(TOOLSDIR)/prepare_rfc_list.py
	$(PY) $(TOOLSDIR)/lint_software_list.py software.json
	$(PY) $(TOOLSDIR)/prepare_software_list.py
	$(PY) $(TOOLSDIR)/prepare_compliance.py
	$(HUGO) version
	$(HUGO)

prepare_docker:
	$(PIP) install --upgrade -r $(TOOLSDIR)/requirements.txt
	$(PY) $(TOOLSDIR)/prepare_xep_list.py
	$(PY) $(TOOLSDIR)/prepare_rfc_list.py
	$(PY) $(TOOLSDIR)/prepare_software_list.py
	$(PY) $(TOOLSDIR)/prepare_compliance.py
	$(HUGO) version
	$(HUGO) --baseURL="http://localhost/" --buildFuture

ssh_upload: publish
	scp -P $(SSH_PORT) -r $(OUTPUTDIR)/* $(SSH_USER)@$(SSH_HOST):$(SSH_TARGET_DIR)

rsync_upload: publish
	rsync -e "ssh -p $(SSH_PORT)" -P -rvz --delete $(OUTPUTDIR)/ $(SSH_USER)@$(SSH_HOST):$(SSH_TARGET_DIR) --cvs-exclude

ftp_upload: publish
	lftp ftp://$(FTP_USER)@$(FTP_HOST) -e "mirror -R $(OUTPUTDIR) $(FTP_TARGET_DIR) ; quit"

.PHONY: html help clean serve publish prepare_docker ssh_upload rsync_upload ftp_upload
