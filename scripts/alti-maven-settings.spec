%global mavenname alti-maven-settings
%global confdir   %{_sysconfdir}/%{name}

Name:		alti-maven-settings
Version:	1.0
Release:	1%{?dist}
Summary:	A RPM wrapper for maven settings.xml

BuildArch:      noarch
Group:		Development/Tools
License:	N/A
URL:		N/A
Source0:	%{_sourcedir}/%{name}.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

# BuildRequires:	
# Requires:	

%description
Just a RPM wrapper to deploy the maven settings into mock environment

%prep
%setup -q -n %{name}

%build

%install
rm -rf %{buildroot}
install -dm 755 %{buildroot}/%{confdir}
install -m 644 %{_builddir}/%{name}/settings.xml %{buildroot}/%{confdir}/

%clean
rm -rf %{buildroot}/%{confdir}

%files
%defattr(755,root,root,755)
%config(noreplace) %{confdir}


%changelog
* Fri May 16 2014 Andrew Lee 20140516
- First version RPM maven setting wrapper

