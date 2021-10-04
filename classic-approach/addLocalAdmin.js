vmname = inputProperties.resourceNames[0];
var admin = inputProperties.customProperties["localAdmin"];

scriptArgs =  '"';
scriptArgs += "Add-LocalGroupMember -Group Administrators -Member '" + admin + "'";
scriptArgs += '"';
