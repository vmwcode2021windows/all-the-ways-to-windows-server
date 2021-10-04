vmname = inputProperties.resourceNames[0];
scriptArgs =  '"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12';
scriptArgs += ";Invoke-WebRequest -Uri " + nppPath + " -Outfile C:\\npp.exe";
scriptArgs += ';C:\\npp.exe /S"';
