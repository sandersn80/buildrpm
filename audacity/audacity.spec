Name:	    audacity	
Version:    3.1.3
Release:    0%{?dist}
Summary:    Audio Editor
Group:	    Audio
License:    GPL-v3.0	
URL:	    https://www.audacityteam.org/

BuildRequires: cmake
BuildRequires: python3-pip
BuildRequires: gtk2-devel
BuildRequires: libatomic
BuildRequires: jack-audio-connection-kit-devel
BuildRequires: alsa-lib-devel
BuildRequires: libSM-devel
BuildRequires: flac-devel

Requires:      gtk2
Requires:      libatomic
Requires:      pipewire-jack-audio-connection-kit
Requires:      alsa-lib
Requires:      libSM
Requires:      flac-libs

%description
Audacity is an easy-to-use, multi-track audio editor and recorder for Windows, macOS, GNU/Linux and other operating systems. Audacity is open source software licensed under GPL, version 2 or later.

    * Recording from any real or virtual audio device that is available to the host system.
    * Export / Import a wide range of audio formats, extensible with FFmpeg.
    * High quality using 32-bit float audio processing.
    * Plug-in Support for multiple audio plug-in formats, including VST, LV2, and AU.
    * Macros for chaining commands and batch processing.
    * Scripting in Python, Perl, or any other language that supports named pipes.
    * Nyquist a powerful built-in scripting language that may also be used to create plug-ins.
    * Editing multi-track editing with sample accuracy and arbitrary sample rates.
    * Accessibility for VI users.
    * Analysis and visualization tools to analyze audio or other signal data.

%prep
if [[ -d audacity ]];then rm -rf audacity; fi
git clone --depth=1 -b Audacity-%{version} https://github.com/audacity/audacity.git
pip3 install conan

%build
cd audacity
export LDFLAGS="-fpie -fpic"
%cmake \
	-DAUDACITY_BUILD_LEVEL=2 \
	-DCMAKE_BUILD_TYPE=Release 
%cmake_build

%install
cd audacity
%cmake_install
cd %{buildroot}/usr/lib64/audacity
chmod 755 *.*

%files
%doc

%changelog
* Wed Jul 27 2022 Naatje80
- Initial version