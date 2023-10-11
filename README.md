# RKE-Build-Packer
This is the POC for creating Ubuntu vm templates using Hashicorp Packer. From those templates, we can create RKE 2 node templates, to automate the buildout of k8s clusters.

templates are stored in the local content library with the name of 'rancher_rke2'+todays date. That gets cloned to 'rancher_rke2' so we can have a constant latest image to use.


## Install Packer
https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli

Install directions for Packer. Currently it’s installed in a docker image to be used in an execution environment in AWX. I locally tested and built the process using the Mac brew option. 

Run this to build out a template. Must be in the same directory when running it.
```
PACKER_LOG=1 packer build -var-file=ubuntu.lab.auto.pkrvars.hcl -var 'password={{ vsphere_lab_password }}' -var 'template_name=rancher_rke2-{{ ansible_date_time.date }}' -var 'ssh_password={{ packer_ssh_password }}' .
```

## Purpose
Packer allows us to create virtual machine templates in vSphere and store them in local content libraries. This method will allow us to replace the current Linux build process, which is tedious, and requires more manual effort. With Packer, we can build vm’s in minutes with automation through Rancher for RKE/RKE2. 

## Folder Description

- http  - Contains the cloud init files for meta-data and user-data. Both files must be present to work correctly. user-data contains the initial install to setup the virtual machine like network settings, create a user, and install packages. Each subfolder uses different network settings.

- mpb_tools - Any scripts used during the Ansible playbook. Currently the script in there, main.py is used for keeping the golden image up to date with the name ‘rancher_rke2’ and keep the older images as backup.

- scripts - These scripts are used post setup of the virtual machine. Once the vm is setup, and rebooted. This would be the final step in adding users, packages, setting permissions, that are specific to what we need in RKE2 or RKE1.

- *_main.yml - These are the Ansible playbooks that are kicked off in AWX. These make it easier to run the packer build process and run the golden image python script at the end.

- ubuntu-2204.pkr.hcl - This is the main Packer build file. This sets configurations on using vSphere, how to build the virtual machine, which content library to add the template to, and build processes.

- ubuntu.*.auto.pkrvars.hcl - These files are the basic variable files for setting the initial virtual machine settings and datacenter location.


Running locally, from the main directory. The following variables are defined, and the passwords are in Cyberark. They are also set as “credentials” in AWX to run in an automated job.

