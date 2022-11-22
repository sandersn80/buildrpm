# rpmbuild
_The rpmbuild scipt is setup to enable rpms to be build in a separate docker
The advantage is:_
* _It keeps your main system clean of any development libraries_
* _Software is not compiled with unnecessary features/options, because previous installations of development files_
* _It will open the docker in interactive mode, in case the build fails at any given point. This allows one to debug the issue, before restarting the build procedure_
* _The build process will automatically check which files need to be added to the rpms. Currently only normal files and development files are supported_
* _If rpm-build from the repo is compiled, a faster (one time compile) is supported_

_The repository also contains the spec files for applications that I've currently build using this software_

_Currently it will only create RPM packages for Enterprise Linux 9 using either AlmaLinux or Rocky-Linux based containers_

## Preparation Enterpirse Linux 7
1. Install docker using your distros package manager. For Centos this could be installed using: 
`sudo yum -y install docker rpm-build rpm-sign`
1. Create a group called docker:
`sudo groupadd docker`
1. Add your user account to the docker group:
`sudo usermod -aG docker $USER`
1. Restart the docker daemon: 
`sudo systemctl restart docker`
1. Either restart your session or execute: 
`newgrp docker`

## Preparation Enterprise Linux (EL) 8 and 9 based
1. EL8 and 9 default supports podman instead of docker. But the podman-docker rpm allows enable docker command support for podman. One additional advantage is no additional configuration is required to allow users to run containers. To install podman-docker execute:
`sudo dnf -y install podman-docker rpm-build rpm-sign` 

## Download rpmbuild
Clone the project using git:
`git clone https://github.com/sandersn80/buildrpm.git`

## Usage
To compile an application already supplied in the repostiory:
1. Navigate to the applicable application directory, inside the rpmbuild directory. E.g.:
`cd rpmbuild/supertuxkart`
1. Now execute the buildrpm command for the specific spec file:
`../rpmbuild $(pwd) almalinux`
or
`../rpmbuild supertuxkart.spec almalinux`

To use this script to build your own application:
1. Navigate to the rpmbuild directory and create a new directory specific for the application for which you want to create an rpm: 
`mkdir -p rpmbuild/MyApplication; cd rpmbuild/MyApplcation`
1. Create the specifile within this directory or download/copy it to this location, in case a specfile is already available.
1. Now execute the buildrpm command for the specific spec file:
`../rpmbuild $(pwd) almalinux`
or
`../rpmbuild myapplication.spec almalinux`
