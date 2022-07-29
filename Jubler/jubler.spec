Name:           jubler
Version:        7.0.3
Release:        1%{?dist}
Summary:        A subtitle editor

License:        GPL-2.0
URL:            https://www.jubler.org

Patch0:		jubler_wrapper.patch
Patch1:		pom_java_11.patch

BuildRequires:  maven

Requires:	java-11-openjdk

%description


%prep
if [[ -d Jubler ]]; then rm -rf Jubler; fi
git clone --depth=1 -b v%{version} https://github.com/teras/Jubler.git
cd Jubler
%patch0 -p0
%patch1 -p0

%build
cd Jubler
mvn clean install -Pdist-generic

%install
cd Jubler
mkdir -p %{buildroot}/opt
tar -xvf modules/installer/target/Jubler-%{version}.tar.bz2 -C %{buildroot}/opt
mkdir -p %{buildroot}/usr/bin
ln -s /opt/jubler/jubler %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications
cp -pv resources/installers/linux/jubler.desktop %{buildroot}/usr/share/applications
for SIZE in {32,64,128}
do
	mkdir -p %{buildroot}/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps
	cp -prv resources/installers/linux/jubler${SIZE}.png %{buildroot}/usr/share/icons/hicolor/${SIZE}x${SIZE}/apps/jubler.png
done

%files

%changelog
* Wed Jul 27 2022 Naatje80
- 
