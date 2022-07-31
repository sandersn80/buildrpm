Name:		image-analyzer
Version:	3.2.5
Release:	1%{?dist}
Summary:	CDEmu Image Analyazer

Group:		System Tools	
License:	GPLv2+
URL:		http://cdemu.sourceforge.net
Source0:        https://github.com/cdemu/cdemu/archive/%{name}-%{version}.tar.gz

BuildRequires:  cmake
BuildRequires:	libmirage-devel

Requires:	    libmirage

%description
Image Analyzer is a simple Gtk+ application that displays tree structure of disc image created by libMirage.

It is mostly intended as a demonstration of libMirage API use, although it can be also used to verify that an image is correctly handled by libMirage.

%prep
%setup -q -n cdemu-%{name}-%{version}/%{name}


%build
%cmake
#make %{?_smp_mflags}
%cmake_build

%install
#make install DESTDIR=%{buildroot}
%cmake_install

%files
%{_bindir}/image-analyzer
%{_datadir}/applications/image-analyzer.desktop
%{_datadir}/locale/ru/LC_MESSAGES/image-analyzer.mo
%{_datadir}/locale/sl/LC_MESSAGES/image-analyzer.mo
%{_datadir}/pixmaps/image-analyzer.svg
%doc



%changelog
* Sun Jul 31 2022 Naatje80
- Initial version