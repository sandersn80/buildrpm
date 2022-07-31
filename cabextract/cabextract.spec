Summary: A program to extract Microsoft Cabinet files
Name: cabextract
Version: 1.9.1
Release: 1
License: GPL
Group: Applications/Archiving
Source: https://www.cabextract.org.uk/%{name}-%{version}.tar.gz
URL: https://www.cabextract.org.uk/
Vendor: Stuart Caie
Packager: Stuart Caie <kyzer@cabextract.org.uk>

%description
Cabinet (.CAB) files are a form of archive, which Microsoft use to
distribute their software, and things like Windows Font Packs. The
cabextract program unpacks these files.

%prep
%setup

%build
%configure
make

%install
rm -rf ${RPM_BUILD_ROOT}
%makeinstall

%files

%changelog
* Sun Jul 31 2022 Naatje80
- Initial version