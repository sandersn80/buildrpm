#! /bin/sh

basedir=`dirname ${0}` 
if [[ -e ${basedir}/settings.sh ]]
then
    . ${basedir}/settings.sh
else
    echo "Make sure to create settings.sh first"
    exit 1
fi

PACKAGE=$(basename ${1} .spec)
DOCKERNAME=$(echo ${PACKAGE}|tr "[:upper:]" "[:lower:]")
OS=${2}

START="@$(date +%s)"

function usage {
    echo "Usage: build-rpm.sh <PACKAGE> <OS>"
    exit 0
}

if [[ ${OS} != "almalinux9" && ${OS} != "rockylinux9" ]]
then
    echo "Currently only almalinux 9 or rockylinux 9 is supported: defaulting to almalinux"
    OS="almalinux"
fi

if [[ ${OS} == "almalinux" ]]
then
    INSTALL_CMD="dnf"
    OS="almalinux:9"
    REPODIR="ALMALINUX9"
    EXTRA_REPOS="crb"
else [[ ${OS} == "rocky-linux" ]]
    INSTALL_CMD="dnf"
    OS="rockylinux:9"
    REPODIR="ROCKYLINUX9"
    EXTRA_REPOS="crb"
fi

if [[ ! -e ${PACKAGE}.spec ]]
then
    echo "Rpm spec file does not exist yet!"
    exit 1
fi

if [[ ! -d ${REPO_STORAGE_PATH}/${REPODIR} ]]
then
	for SUBDIR in {"RPMS","SRPMS"}
	do
		mkdir -p ${REPO_STORAGE_PATH}/${REPODIR}/${SUBDIR}
		createrepo ${REPO_STORAGE_PATH}/${REPODIR}/${SUBDIR}
	done
fi

LOCAL_RPM_PATH=$(ls ${REPO_STORAGE_PATH}/${REPODIR}/RPMS/x86_64/rpm-build*.rpm|sort -d|head -1)
LOCAL_RPM_FILE=$(basename ${LOCAL_RPM_PATH})


# Ensure the container is not running
docker stop ${DOCKERNAME}-build
docker rm ${DOCKERNAME}-build

BUILDSCRIPT="""
#! /bin/sh
set -o pipefail
spectool -R -g ~/rpmbuild/SPECS/${PACKAGE}.spec
yum-builddep -y ~/rpmbuild/SPECS/${PACKAGE}.spec
rpmbuild -bc ~/rpmbuild/SPECS/${PACKAGE}.spec
if [[ \${?} -ne 0 ]]
then
    exit 1
fi
rpmbuild --short-circuit -bi ~/rpmbuild/SPECS/${PACKAGE}.spec
rpmbuild -bl ~/rpmbuild/SPECS/${PACKAGE}.spec 2>&1| sort -u| grep '^   '| grep -v '(but unpackaged)'| sed 's/^   //'|sed 's/^\(.*\)$/\"\1\"/' > /tmp/package_files.log
sed -i -e 's/\/usr\/bin\//%{_bindir}\//g' /tmp/package_files.log
sed -i -e 's/\/usr\/sbin\//%{_sbindir}\//g' /tmp/package_files.log
sed -i -e 's/\/usr\/lib64\//%{_libdir}\//g' /tmp/package_files.log
sed -i -e 's/\/usr\/include\//%{_includedir}\//g' /tmp/package_files.log
sed -i -e 's/\/usr\/libexec\//%{_libexecdir}\//g' /tmp/package_files.log
sed -i -e 's/\/usr\/share\/man\//%{_mandir}\//g' /tmp/package_files.log
sed -i -e 's/\/usr\/share\/info\//%{_infodir}\//g' /tmp/package_files.log
sed -i -e 's/\/usr\/share\/doc\//%{_docdir}\//g' /tmp/package_files.log
sed -i -e 's/\/usr\/share\//%{_datadir}\//g' /tmp/package_files.log
sed -i -e 's/\/etc\//%{_sysconfdir}\//g' /tmp/package_files.log
sed -i -e 's/\/run\//%{_rundir}\//g' /tmp/package_files.log
sed -i -e 's/\/var\/lib\//%{_sharedstate-dir}\//g' /tmp/package_files.log
sed -i -e 's/\/usr\//%{_exec_prefix}\//g' /tmp/package_files.log
cat /tmp/package_files.log|egrep -v -e '*[.]cmake\"$|*[.]so\"$|*[.]h\"$|*[.]pc\"$' > /tmp/FILES.LOG
cat /tmp/package_files.log|egrep -e '*[.]cmake\"$|*[.]so\"$|*[.]h\"$|*[.]pc\"$' > /tmp/DEVEL_FILES.LOG
if [[ \$(grep -c '%files devel' /root/rpmbuild/SPECS/${PACKAGE}.spec) -ne 0 ]]
then
    sed -i -e '/%files devel[\s]*$/r /tmp/DEVEL_FILES.LOG' /root/rpmbuild/SPECS/${PACKAGE}.spec
else
    sed -i -e '/%files[\s]*$/r /tmp/DEVEL_FILES.LOG' /root/rpmbuild/SPECS/${PACKAGE}.spec
fi
sed -i -e '/%files[\s]*$/r /tmp/FILES.LOG' /root/rpmbuild/SPECS/${PACKAGE}.spec
if [[ -n \$(rpmbuild --help|grep nobuildstage) ]]
then
        rpmbuild --noclean --nobuildstage --noprep -ba ~/rpmbuild/SPECS/${PACKAGE}.spec
else
        rpmbuild --noclean -ba ~/rpmbuild/SPECS/${PACKAGE}.spec
fi
"""

DOCKERFILE="""
FROM ${OS}
USER root
VOLUME /${REPODIR}
RUN ${INSTALL_CMD} clean all; ${INSTALL_CMD} -y update; \
    ${INSTALL_CMD} -y groupinstall \"Development Tools\"; \
    ${INSTALL_CMD} -y install rpmdevtools yum-utils epel-release; \
    echo \"continue\"; \
    if [[ -n "${EXTRA_REPOS}" ]]; then yum-config-manager --enable ${EXTRA_REPOS}; fi
RUN mkdir -p ~/rpmbuild/{SPECS,SOURCES}; \
    echo -e '%debug_package %{nil}\n%_rpmdir   /${REPODIR}/RPMS\n%_srcrpmdir   /${REPODIR}/SRPMS\n%_builddir	/tmp/rpmbuild/BUILD\n%_buildrootdir /tmp/rpmbuild/BUILDROOT\n%_sourcedir    %(echo \$HOME)/rpmbuild/SOURCES\n%_specdir   %(echo \$HOME)/rpmbuild/SOURCES' > ~/.rpmmacros
COPY ${PACKAGE}.spec /root/rpmbuild/SPECS
WORKDIR /root/rpmbuild
RUN echo -e '[localrepo]\nname=localrepo\nbaseurl=file:///${REPODIR}/RPMS\ngpgcheck=0\nenabled=1' > /etc/yum.repos.d/local.repo 
COPY build.sh /root/rpmbuild
"""

# If own compiled rpm-build exists (to support single/faster builds)
# Force the installation of the own compiled version
if [[ -e ${LOCAL_RPM_PATH} ]]
then
    DOCKERFILE="""${DOCKERFILE}RUN echo -e 'exclude=rpm-build*' >>  /etc/yum.repos.d/local.repo
COPY ${LOCAL_RPM_FILE} /root/rpmbuild
RUN rpm -ivh --nodeps --force /root/rpmbuild/${LOCAL_RPM_FILE}
    """
fi

if [[ -d Build ]]
then
    rm -rf Build
fi

mkdir Build
echo "${BUILDSCRIPT}" > Build/build.sh; chmod +x Build/build.sh
SOURCE_FILES=`rpmspec -P ${PACKAGE}.spec 2>/dev/null|grep '^Source[0-9]\+:\|^Patch[0-9]\+:' | grep -v -e 'http\|https'|tr -d ' '|cut -d ':' -f2-`
if [[ -n ${SOURCE_FILES} ]]; then DOCKERFILE="${DOCKERFILE}COPY"; fi
for FILE in ${SOURCE_FILES}
do
    if [[ -e ${FILE} ]]
    then
        cp ${FILE} Build/
        DOCKERFILE="${DOCKERFILE} ${FILE}"
    else
        echo "ERROR: Source or patch file ${FILE} not found!"
    fi
done 
if [[ -n ${SOURCE_FILES} ]]; then DOCKERFILE="${DOCKERFILE} /root/rpmbuild/SOURCES/"; fi

if [[ -e ${LOCAL_RPM_PATH} ]]
then
    cp ${LOCAL_RPM_PATH} Build/
fi 

echo "${DOCKERFILE}" > Build/Dockerfile
cp ${PACKAGE}.spec Build/
cd Build
docker build -t ${DOCKERNAME} .
if [[ ${?} == 0 ]]
then
    docker run --name=${DOCKERNAME}-build --security-opt="label=disable" -v ${REPO_STORAGE_PATH}/${REPODIR}:/${REPODIR} ${DOCKERNAME} sh ./build.sh &&
        (   if [[ $(gpg --list-keys|grep -c "${RPM_KEY_SINGER_DESCRIPTION}"|wc -l) -gt 0 ]]; 
            then 
                find ${REPO_STORAGE_PATH}/${REPODIR} -type f -iname '*.rpm' -newerct "${START}" -exec rpmsign --addsign --key-id="${RPM_KEY_SINGER_DESCRIPTION}" '{}' \;; 
                fi; \
            createrepo -v --update ${REPO_STORAGE_PATH}/${REPODIR}/RPMS; createrepo -v --update ${REPO_STORAGE_PATH}/${REPODIR}/SRPMS; \
            docker rm ${DOCKERNAME}-build ) ||
        ( echo -e "\n############################################################\nERROR Compiling: ${PACKAGE}, opening docker for debugging....\n############################################################";
            docker commit ${DOCKERNAME}-build debug-container; 
            docker rm ${DOCKERNAME}-build; docker run --rm -ti -v ${REPO_STORAGE_PATH}/${REPODIR}:/${REPODIR} debug-container /bin/bash )
        #find -type f -newerct "${START}" -exec  && 
fi
