Name:		cdemu-client
Version:	3.2.5
Release:	1%{?dist}
Summary:	CDEmu client is a simple command-line client for controlling CDEmu daemon.

Group:		System Tools	
License:	GPLv2+
URL:		http://cdemu.sourceforge.net
Source0:        https://github.com/cdemu/cdemu/archive/%{name}-%{version}.tar.gz

BuildRequires:  cmake
BuildRequires:	libmirage-devel

Requires:	libmirage
Requires:	vhba-module
Requires:	cdemu-daemon

%description
CDEmu client is a simple command-line client for controlling CDEmu daemon.

It provides a way to perform the key tasks related to controlling the CDEmu daemon, such as loading and unloading devices, displaying devices' status and retrieving/setting devices' debug masks.

%prep
%setup -q -n cdemu-%{name}-%{version}/%{name}


%build
%cmake
%cmake_build


%install
%cmake_install

%files
%doc

%changelog
* Sun Jul 31 2022 Naatje80
- Initial version