Name:		gcdemu	
Version:	3.2.5
Release:	1%{?dist}
Summary:	gCDEmu is a GTK application for controlling CDEmu daemon.

Group:		System Tools
License:	GPLv2+
URL:		http://cdemu.sourceforge.net
Source0:    https://github.com/cdemu/cdemu/archive/%{name}-%{version}.tar.gz

BuildRequires:  cmake
BuildRequires:  libmirage-devel

Requires:	    libmirage
Requires:	    vhba-module
Requires:	    cdemu-daemon
Requires:	    cdemu-client

%description
gCDEmu is a GTK application for controlling CDEmu daemon.

It provides a graphic interface that allows performing the key tasks related to controlling the CDEmu daemon, such as loading and unloading devices, displaying devices' status and retrieving/setting devices' debug masks.

In addition, the application listens to signals emitted by CDEmu daemon and provides notifications via libnotify (provided that python bindings are installed).

%prep
cat << EOF > %{_sourcedir}/gcdemu.desktop
[Desktop Entry]
Name=gCDEmu
Comment=gCDEmu GUI
Icon=gcdemu
Terminal=false
Type=Application
StartupNotify=false
Categories=GTK;System;
TryExec=gcdemu
Exec=gcdemu
X-GNOME-Autostart-Phase=Applications
X-GNOME-Autostart-Notify=true
X-GNOME-Autostart-enabled=true
# X-KDE-autostart-phase=2
# X-KDE-autostart-after=panel
# X-KDE-StartupNotify=false
EOF
%setup -q -n cdemu-%{name}-%{version}/%{name}


%build
%cmake
#make %{?_smp_mflags}
%cmake_build

%install
#make install DESTDIR=%{buildroot}
%cmake_install
install -d %{buildroot}/etc/xdg/autostart
install -m 644 %{_sourcedir}/gcdemu.desktop %{buildroot}/etc/xdg/autostart

%files
%doc

%post
glib-compile-schemas %{_datadir}/glib-2.0/schemas 2>/dev/null

%changelog
* Sun Jul 31 2022 Naatje80
- Initial version