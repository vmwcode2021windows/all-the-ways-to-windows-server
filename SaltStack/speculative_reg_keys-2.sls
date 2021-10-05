Speculative Vulnerability Registry Check1:
 reg.present:
  - name: 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
  - vname: FeatureSettingsOverride
  - vdata: 72
  - vtype: REG_DWORD
 
Speculative Vulnerability Registry Check2:  
 reg.present:
  - name: 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
  - vname: FeatureSettingsOverrideMask
  - vdata: 3
  - vtype: REG_DWORD

# These Reg Keys are required for Windows to enable Speculation vuln remediation