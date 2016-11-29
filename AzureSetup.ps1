########
#Config#
########

$Acro = "TST1"
$PhyLoc = "centralus"
$SubID = "90e92d95-285f-4fa8-bab4-f728a29c976c"

#Availability Sets
$FaultDomains = 3
$UpdateDomains = 5

$SETest_Bool = $TRUE
$SOTest_Bool = $TRUE
$SEProd_Bool = $TRUE
$SOProd_Bool = $TRUE
$DC_Bool = $TRUE

#VM Sizes#
$DC_Size = "Standard_A3"
$PSEA_Size = "Standard_A3"
$PSES_Size = "Standard_A3"
$PSEW1_Size = "Standard_A3"
$PSEW2_Size = "Standard_A3"
$PSOS_Size = "Standard_A3"
$PSOW1_Size = "Standard_A3"
$PSOW2_Size = "Standard_A3"
$TSEA_Size = "Standard_A3"
$TSES_Size = "Standard_A3"
$TSEW_Size = "Standard_A3"
$TSOS_Size = "Standard_A3"
$TSOW_Size = "Standard_A3"


############
#AutoConfig#
############

$cred = Get-Credential -Message "Type the name and pass of the local admin account"

$RG_Name = $Acro + "_Group"

#Storage Names#
$ProdSESto = $Acro.ToLower() + "prodse"
$ProdSOSto = $Acro.ToLower() + "prodso"
$LocalSto = $Acro.ToLower() + "local"
$GeoSto = $Acro.ToLower() + "prodgeo"
$ProdDiagSto = $Acro.ToLower() + "proddiagnostics"
$TestDiagSto = $Acro.ToLower() + "testdiagnostics"
$TestSESto = $Acro.ToLower() + "testse"
$TestSOSto = $Acro.ToLower() + "testso"

if($DC_Bool)
    {
        $AZDC = $Acro + "-AZDC01"
    }
if($SEProd_Bool)
    {
        $PSEA = $Acro + "-PRODSEAPP01"
        $PSES = $Acro + "-PRODSESQL01"
        $PSEW1 = $Acro + "-PRODSEWEB01"
        $PSEW2 = $Acro + "-PRODSEWEB02"


    }
if($SETest_Bool)
    {
        $TSEA = $Acro + "-TESTSEAPP01"
        $TSES = $Acro + "-TESTSESQL01"
        $TSEW = $Acro + "-TESTSEWEB01"
    }
if($SOProd_Bool)
    {
        $PSOS = $Acro + "-PRODSOSQL01"
        $PSOW1 = $Acro + "-PRODSOWEB01"
        $PSOW2 = $Acro + "-PRODSOWEB02"
    }
if($SOTest_Bool)
    {
        $TSOS = $Acro + "-TESTSOSQL01"
        $TSOW = $Acro + "-TESTSOWEB01"
    }


Add-AzureRmAccount
Set-AzureRmContext -SubscriptionID $SubID
New-AzureRmResourceGroup -Name $RG_Name -Location $PhyLoc

##New-AzureRmResourceGroupDeployment -ResourceGroupName $RG_Name

#########
#Storage#
#########

$Local_Sto = New-AzureRmStorageAccount -ResourceGroupName $RG_Name -Name $LocalSto -SkuName "Standard_LRS" -Kind "Storage" -Location $PhyLoc

if($SEProd_Bool -or $SETest_Bool) 
    {
        $ProdDiag_Sto = New-AzureRmStorageAccount -ResourceGroupName $RG_Name -Name $ProdDiagSto -SkuName "Standard_LRS" -Kind "Storage" -Location $PhyLoc
    }
if($SOProd_Bool -or $SOTest_Bool)
    {
        $TestDiag_Sto = New-AzureRmStorageAccount -ResourceGroupName $RG_Name -Name $TestDiagSto -SkuName "Standard_LRS" -Kind "Storage" -Location $PhyLoc
    }

if($SEProd_Bool) 
    {
        $ProdSE_Sto = New-AzureRmStorageAccount -ResourceGroupName $RG_Name -Name $ProdSESto -SkuName "Standard_LRS" -Kind "Storage" -Location $PhyLoc
    }
if($SETest_Bool)
    {
        $TestSE_Sto = New-AzureRmStorageAccount -ResourceGroupName $RG_Name -Name $TestSESto -SkuName "Standard_LRS" -Kind "Storage" -Location $PhyLoc
    }
if($SOProd_Bool) 
    {
        $ProdSO_Sto = New-AzureRmStorageAccount -ResourceGroupName $RG_Name -Name $ProdSOSto -SkuName "Standard_LRS" -Kind "Storage" -Location $PhyLoc
    }
if($SOTest_Bool)
    {
        $TestSO_Sto = New-AzureRmStorageAccount -ResourceGroupName $RG_Name -Name $TestSOSto -SkuName "Standard_LRS" -Kind "Storage" -Location $PhyLoc
    }

############
#Avail Sets#
############


if($SEProd_Bool)
    {
        $PRODSE_AS = New-AzureRmAvailabilitySet -ResourceGroupName $RG_Name -Name "PRODSEWEB" -Location $PhyLoc -PlatformFaultDomainCount $FaultDomains -PlatformUpdateDomainCount $UpdateDomains
    }
if($SOProd_Bool)
    {
        $PRODS0_AS = New-AzureRmAvailabilitySet -ResourceGroupName $RG_Name -Name "PRODSOWEB" -Location $PhyLoc -PlatformFaultDomainCount $FaultDomains -PlatformUpdateDomainCount $UpdateDomains
    }

#########
#Network#
#########

$ProdSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name "PROD" -AddressPrefix 172.16.50.0/26
$TestSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name "TEST" -AddressPrefix 172.16.50.80/28
$GatewaySubnet = New-AzureRmVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix 172.16.50.64/28

$vNetName = $Acro.ToUpper()
$vnet = New-AzureRmVirtualNetwork -Name $vNetName -ResourceGroupName $RG_Name -Location $PhyLoc -AddressPrefix 172.16.50.0/24 -Subnet $ProdSubnet,$TestSubnet,$GateWaySubnet
##DNS SERVER - Provided

#########################
#Network Security Groups#
#########################

$NSRDP = New-AzureRmNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" -Access Allow -Protocol TCP -Direction Inbound -Priority 1000 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
$NSHTTP = New-AzureRmNetworkSecurityRuleConfig -Name http-rule -Description "Allow HTTP" -Access Allow -Protocol TCP -Direction Inbound -Priority 1010 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80
$NSHTTPS = New-AzureRmNetworkSecurityRuleConfig -Name https-rule -Description "Allow HTTPS" -Access Allow -Protocol Tcp -Direction Inbound -Priority 1020 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443
$NSSQL = New-AzureRmNetworkSecurityRuleConfig -Name sql-rule -Description "Allow SQL" -Access Allow -Protocol TCP -Direction Inbound -Priority 1030 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 1443

if($DC_Bool)
    {
        $AZDC_NSG = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RG_Name -Location $PhyLoc -Name ($Acro + "-AZDC01") -SecurityRules $NSRDP
    }
if($SEProd_Bool)
    {
        $PSEA_NSG = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RG_Name -Location $PhyLoc -Name ($Acro + "-PRDSEAPP") -SecurityRules $NSRDP
		$PSES_NSG = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RG_Name -Location $PhyLoc -Name ($Acro + "-PRDSESQL") -SecurityRules $NSRDP, $NSHTTP, $NSSQL
		$PSEW1_NSG = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RG_Name -Location $PhyLoc -Name ($Acro + "-PRDSEWEB1") -SecurityRules $NSRDP, $NSHTTP, $NSHTTPS
		$PSEW2_NSG = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RG_Name -Location $PhyLoc -Name ($Acro + "-PRDSEWEB2") -SecurityRules $NSRDP, $NSHTTP, $NSHTTPS
    }
if($SETest_Bool)
    {
        $TSEA_NSG = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RG_Name -Location $PhyLoc -Name ($Acro + "-TSTSEAPP") -SecurityRules $NSRDP
		$TSES_NSG = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RG_Name -Location $PhyLoc -Name ($Acro + "-TSTSESQL") -SecurityRules $NSRDP
		$TSEW_NSG = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RG_Name -Location $PhyLoc -Name ($Acro + "-TSTSEWEB") -SecurityRules $NSRDP, $NSHTTPS
    }
if($SOProd_Bool)
    {
		$PSOS_NSG = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RG_Name -Location $PhyLoc -Name ($Acro + "-PRDSOSQL") -SecurityRules $NSRDP
		$PSOW1_NSG = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RG_Name -Location $PhyLoc -Name ($Acro + "-PRDSOWEB1") -SecurityRules $NSRDP, $NSHTTP, $NSHTTPS
		$PSOW2_NSG = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RG_Name -Location $PhyLoc -Name ($Acro + "-PRDSOWEB2") -SecurityRules $NSRDP, $NSHTTP, $NSHTTPS
       
    }
if($SOTest_Bool)
    {  
		$TSOS_NSG = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RG_Name -Location $PhyLoc -Name ($Acro + "-TSTSOSQL") -SecurityRules $NSRDP
		$TSOW_NSG = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RG_Name -Location $PhyLoc -Name ($Acro + "-TSTSOWEB") -SecurityRules $NSRDP, $NSHTTP, $NSHTTPS
    }

##############
#IP Addresses#
##############
if($DC_Bool)
    {
        $AZDC_IP = New-AzureRmPublicIPAddress -Name $AZDC -ResourceGroupName $RG_Name -Location $PhyLoc -AllocationMethod Dynamic
    }
if($SEProd_Bool)
    {
        $PSEA_IP = New-AzureRmPublicIPAddress -Name $PSEA -ResourceGroupName $RG_Name -Location $PhyLoc -AllocationMethod Dynamic
        $PSES_IP = New-AzureRmPublicIPAddress -Name $PSES -ResourceGroupName $RG_Name -Location $PhyLoc -AllocationMethod Dynamic
        $PSEW1_IP = New-AzureRmPublicIPAddress -Name $PSEW1 -ResourceGroupName $RG_Name -Location $PhyLoc -AllocationMethod Dynamic
        $PSEW2_IP = New-AzureRmPublicIPAddress -Name $PSEW2 -ResourceGroupName $RG_Name -Location $PhyLoc -AllocationMethod Dynamic
    }
if($SETest_Bool)
    {
        $TSEA_IP = New-AzureRmPublicIPAddress -Name $TSEA -ResourceGroupName $RG_Name -Location $PhyLoc -AllocationMethod Dynamic
        $TSES_IP = New-AzureRmPublicIPAddress -Name $TSES -ResourceGroupName $RG_Name -Location $PhyLoc -AllocationMethod Dynamic
        $TSEW_IP = New-AzureRmPublicIPAddress -Name $TSEW -ResourceGroupName $RG_Name -Location $PhyLoc -AllocationMethod Dynamic
    }
if($SOProd_Bool)
    {
        $PSOS_IP = New-AzureRmPublicIPAddress -Name $PSOS -ResourceGroupName $RG_Name -Location $PhyLoc -AllocationMethod Dynamic
        $PSOW1_IP = New-AzureRmPublicIPAddress -Name $PSOW1 -ResourceGroupName $RG_Name -Location $PhyLoc -AllocationMethod Dynamic
        $PSOW2_IP = New-AzureRmPublicIPAddress -Name $PSOW2 -ResourceGroupName $RG_Name -Location $PhyLoc -AllocationMethod Dynamic
    }
if($SOTest_Bool)
    {
        $TSOS_IP = New-AzureRmPublicIPAddress -Name $TSOS -ResourceGroupName $RG_Name -Location $PhyLoc -AllocationMethod Dynamic
        $TSOW_IP = New-AzureRmPublicIPAddress -Name $TSOW -ResourceGroupName $RG_Name -Location $PhyLoc -AllocationMethod Dynamic
    }

###############
#Load Balancer#
###############

if($SEProd_Bool)
    {
		$SELB_Name = $Acro + "-SEWEBLoadBalancer"
		$SE_BEAddressPool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name ($Acro + "prodsewebbackendpool")
		$FE_IP_Name = $Acro + "-PRODSEWEBDynamicIP_Public"
		$publicIP = New-AzureRmPublicIPAddress -Name $FE_IP_Name -ResourceGroupName $RG_Name -Location $PhyLoc -AllocationMethod Dynamic -DomainNameLabel ($Acro.ToLower() + "prodse")
		$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig -Name "LoadBalancerFrontEnd" -PublicIpAddress $publicIP
		$inboundNATRule1 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "http" -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 80 -BackendPort 80 
		$inboundNATRule2 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "https" -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 443 -BackendPort 443 
		$HTTPProbe = New-AzureRmLoadBalancerProbeConfig -Name "httpprobe" -RequestPath "HealthProbe.aspx" -Protocol tcp -Port 80 -IntervalInSeconds 5 -ProbeCount 2
		$HTTPSProbe = New-AzureRmLoadBalancerProbeConfig -Name "httpsprobe" -RequestPath "HealthProbe.aspx" -Protocol tcp -Port 443 -IntervalInSeconds 5 -ProbeCount 2 
		$Probes = $HTTPProbe, $HTTPSProbe
		$LBRule1 = New-AzureRmLoadBalancerRuleConfig -Name "http" -FrontendIpConfiguration $frontendIP -BackendAddressPool $SE_BEAddressPool -Probe $HTTPProbe -Protocol tcp -FrontendPort 80 -BackendPort 80
		$LBRule2 = New-AzureRmLoadBalancerRuleConfig -Name "https" -FrontendIpConfiguration $frontendIP -BackendAddressPool $SE_BEAddressPool -Probe $HTTPSProbe -Protocol tcp -FrontendPort 443 -BackendPort 443
		$SELB = New-AzureRmLoadBalancer -ResourceGroupName $RG_Name -Name $SELB_Name -Location $PhyLoc -FrontendIpConfiguration $frontendIP -InboundNatRule $inboundNATRule1, $inboundNATRule2 -LoadBalancingRule $LBRule1, $LBRule2 -Probe $Probes
	}

if($SOTest_Bool)
    {
		$SOLB_Name = $Acro + "-SOWEBLoadBalancer"
		$SO_BEAddressPool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name ($Acro + "prodsowebbackendpool")
		$FE_IP_Name = $Acro + "-PRODSOWEBDynamicIP_Public"
		$FE_IP = New-AzureRmPublicIPAddress -Name $FE_IP_Name -ResourceGroupName $RG_Name -Location $PhyLoc -AllocationMethod Dynamic
		$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig -Name LoadBalancerFrontEnd -PublicIpAddressId $FE_IP.Id
		$inboundNATRule1 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "http" -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 80 -BackendPort 80 
		$inboundNATRule2 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "https" -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 443 -BackendPort 443 
		$NATRules = $inboundNATRule1, $inboundNATRule2
		$HTTPProbe = New-AzureRmLoadBalancerProbeConfig -Name "httpprobe" -RequestPath "HealthProbe.aspx" -Protocol tcp -Port 80 -IntervalInSeconds 5 -ProbeCount 2
		$HTTPSProbe = New-AzureRmLoadBalancerProbeConfig -Name "httpsprobe" -RequestPath "HealthProbe.aspx" -Protocol tcp -Port 443 -IntervalInSeconds 5 -ProbeCount 2 
		$Probes = $HTTPProbe, $HTTPSProbe
		$LBRule1 = New-AzureRmLoadBalancerRuleConfig -Name "http" -FrontendIpConfiguration $frontendIP -BackendAddressPool $SO_BEAddressPool -Probe $HTTPProbe -Protocol tcp -FrontendPort 80 -BackendPort 80
		$LBRule2 = New-AzureRmLoadBalancerRuleConfig -Name "https" -FrontendIpConfiguration $frontendIP -BackendAddressPool $SO_BEAddressPool -Probe $HTTPSProbe -Protocol tcp -FrontendPort 443 -BackendPort 443
		$SOLB = New-AzureRmLoadBalancer -ResourceGroupName $RG_Name -Name $SOLB_Name -Location $PhyLoc -FrontendIpConfiguration $frontendIP -InboundNatRule $NATRules -LoadBalancingRule $LBRule1, $LBRule2 -Probe $Probes
	}

######
#NICs#
######

if($DC_Bool)
    {
        $AZDC_NIC = New-AzureRmNetworkInterface -Name $AZDC -ResourceGroupName $RG_Name -Location $PhyLoc -SubnetId $vnet.Subnets[1].Id -PublicIpAddressId $AZDC_IP.Id -NetworkSecurityGroupID $AZDC_NSG.ID
    }
if($SEProd_Bool)
    {
        $PSEA_NIC = New-AzureRmNetworkInterface -Name $PSEA -ResourceGroupName $RG_Name -Location $PhyLoc -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $PSEA_IP.Id -NetworkSecurityGroupID $PSEA_NSG.ID
        $PSES_NIC = New-AzureRmNetworkInterface -Name $PSES -ResourceGroupName $RG_Name -Location $PhyLoc -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $PSES_IP.Id -NetworkSecurityGroupID $PSES_NSG.ID
        $PSEW1_NIC = New-AzureRmNetworkInterface -Name $PSEW1 -ResourceGroupName $RG_Name -Location $PhyLoc -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $PSEW1_IP.Id -NetworkSecurityGroupID $PSEW1_NSG.ID
        $PSEW2_NIC = New-AzureRmNetworkInterface -Name $PSEW2 -ResourceGroupName $RG_Name -Location $PhyLoc -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $PSEW2_IP.Id -NetworkSecurityGroupID $PSEW2_NSG.ID
    }
if($SETest_Bool)
    {
        $TSEA_NIC = New-AzureRmNetworkInterface -Name $TSEA -ResourceGroupName $RG_Name -Location $PhyLoc -SubnetId $vnet.Subnets[1].Id -PublicIpAddressId $TSEA_IP.Id -NetworkSecurityGroupID $TSEA_NSG.ID
        $TSES_NIC = New-AzureRmNetworkInterface -Name $TSES -ResourceGroupName $RG_Name -Location $PhyLoc -SubnetId $vnet.Subnets[1].Id -PublicIpAddressId $TSES_IP.Id -NetworkSecurityGroupID $TSES_NSG.ID
        $TSEW_NIC = New-AzureRmNetworkInterface -Name $TSEW -ResourceGroupName $RG_Name -Location $PhyLoc -SubnetId $vnet.Subnets[1].Id -PublicIpAddressId $TSEW_IP.Id -NetworkSecurityGroupID $TSEW_NSG.ID
    }
if($SOProd_Bool)
    { 
        $PSOS_NIC = New-AzureRmNetworkInterface -Name $PSOS -ResourceGroupName $RG_Name -Location $PhyLoc -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $PSOS_IP.Id -NetworkSecurityGroupID $PSOS_NSG.ID
        $PSOW1_NIC = New-AzureRmNetworkInterface -Name $PSOW1 -ResourceGroupName $RG_Name -Location $PhyLoc -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $PSOW1_IP.Id -NetworkSecurityGroupID $PSOW1_NSG.ID
        $PSOW2_NIC = New-AzureRmNetworkInterface -Name $PSOW2 -ResourceGroupName $RG_Name -Location $PhyLoc -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $PSOW2_IP.Id -NetworkSecurityGroupID $PSOW2_NSG.ID
    }
if($SOTest_Bool)
    {
        $TSOS_NIC = New-AzureRmNetworkInterface -Name $TSOS -ResourceGroupName $RG_Name -Location $PhyLoc -SubnetId $vnet.Subnets[1].Id -PublicIpAddressId $TSOS_IP.Id -NetworkSecurityGroupID $TSOS_NSG.ID
        $TSOW_NIC = New-AzureRmNetworkInterface -Name $TSOW -ResourceGroupName $RG_Name -Location $PhyLoc -SubnetId $vnet.Subnets[1].Id -PublicIpAddressId $TSOW_IP.Id -NetworkSecurityGroupID $TSOW_NSG.ID
    }

##################
#Virtual Machines#
##################

if($DC_Bool)
    {
        $vm = New-AzureRmVMConfig -VMname $AZDC -VMSize $DC_Size
        $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $AZDC -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
        $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -SKUs 2012-R2-Datacenter -Version "latest"
        $vm = Add-AzureRmVMNetworkInterface -vm $vm -Id $AZDC_NIC.Id
        $blobPath = "vhds/" + $AZDC + ".vhd"
        $osDiskUri = $Local_Sto.PrimaryEndpoints.Blob.ToString() + $blobPath
        $vm = Set-AzureRmVMOSDisk -VM $vm -Name $AZDC -VhdUri $osDiskUri -CreateOption FromImage
        New-AzureRmVM -ResourceGroupName $RG_Name -Location $PhyLoc -VM $vm
    }
if($SEProd_Bool)
    {
        $vm = New-AzureRmVMConfig -VMname $PSEA -VMSize $PSEA_Size
        $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $PSEA -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
        $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -SKUs 2012-R2-Datacenter -Version "latest"
        $vm = Add-AzureRmVMNetworkInterface -vm $vm -Id $PSEA_NIC.Id
        $blobPath = "vhds/" + $PSEA + ".vhd"
        $osDiskUri = $ProdSE_Sto.PrimaryEndpoints.Blob.ToString() + $blobPath
        $vm = Set-AzureRmVMOSDisk -VM $vm -Name $PSEA -VhdUri $osDiskUri -CreateOption FromImage
        New-AzureRmVM -ResourceGroupName $RG_Name -Location $PhyLoc -VM $vm

        $vm = New-AzureRmVMConfig -VMname $PSES -VMSize $PSES_Size
        $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $PSES -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
        $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -SKUs 2012-R2-Datacenter -Version "latest"
        $vm = Add-AzureRmVMNetworkInterface -vm $vm -Id $PSES_NIC.Id
        $blobPath = "vhds/" + $PSEs + ".vhd"
        $osDiskUri = $ProdSE_Sto.PrimaryEndpoints.Blob.ToString() + $blobPath
        $vm = Set-AzureRmVMOSDisk -VM $vm -Name $PSES -VhdUri $osDiskUri -CreateOption FromImage
        New-AzureRmVM -ResourceGroupName $RG_Name -Location $PhyLoc -VM $vm

        $avName = Get-AzureRMAvailabilitySet -Name "PRODSEWEB" -ResourceGroupName $RG_Name
		$vm = New-AzureRmVMConfig -VMname $PSEW1 -VMSize $PSEW1_Size -AvailabilitySetId $avName
        $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $PSEW1 -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
        $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -SKUs 2012-R2-Datacenter -Version "latest"
        $vm = Add-AzureRmVMNetworkInterface -vm $vm -Id $PSEW1_NIC.Id
        $blobPath = "vhds/" + $PSEW1 + ".vhd"
        $osDiskUri = $ProdSE_Sto.PrimaryEndpoints.Blob.ToString() + $blobPath
        $vm = Set-AzureRmVMOSDisk -VM $vm -Name $PSEW1 -VhdUri $osDiskUri -CreateOption FromImage
        New-AzureRmVM -ResourceGroupName $RG_Name -Location $PhyLoc -VM $vm

        $vm = New-AzureRmVMConfig -VMname $PSEW2 -VMSize $PSEW2_Size -AvailabilitySetId $avName
        $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $PSEW2 -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
        $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -SKUs 2012-R2-Datacenter -Version "latest"
        $vm = Add-AzureRmVMNetworkInterface -vm $vm -Id $PSEW2_NIC.Id
        $blobPath = "vhds/" + $PSEW2 + ".vhd"
        $osDiskUri = $ProdSE_Sto.PrimaryEndpoints.Blob.ToString() + $blobPath
        $vm = Set-AzureRmVMOSDisk -VM $vm -Name $PSEW2 -VhdUri $osDiskUri -CreateOption FromImage
        New-AzureRmVM -ResourceGroupName $RG_Name -Location $PhyLoc -VM $vm
    }
if($SETest_Bool)
    {
        $vm = New-AzureRmVMConfig -VMname $TSEA -VMSize $TSEA_Size
        $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $TSEA -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
        $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -SKUs 2012-R2-Datacenter -Version "latest"
        $vm = Add-AzureRmVMNetworkInterface -vm $vm -Id $TSEA_NIC.Id
        $blobPath = "vhds/" + $TSEA + ".vhd"
        $osDiskUri = $TestSE_Sto.PrimaryEndpoints.Blob.ToString() + $blobPath
        $vm = Set-AzureRmVMOSDisk -VM $vm -Name $TSEA -VhdUri $osDiskUri -CreateOption FromImage
        New-AzureRmVM -ResourceGroupName $RG_Name -Location $PhyLoc -VM $vm

        $vm = New-AzureRmVMConfig -VMname $TSES -VMSize $TSES_Size
        $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $TSES -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
        $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -SKUs 2012-R2-Datacenter -Version "latest"
        $vm = Add-AzureRmVMNetworkInterface -vm $vm -Id $TSES_NIC.Id
        $blobPath = "vhds/" + $TSES + ".vhd"
        $osDiskUri = $TestSE_Sto.PrimaryEndpoints.Blob.ToString() + $blobPath
        $vm = Set-AzureRmVMOSDisk -VM $vm -Name $TSES -VhdUri $osDiskUri -CreateOption FromImage
        New-AzureRmVM -ResourceGroupName $RG_Name -Location $PhyLoc -VM $vm

        $vm = New-AzureRmVMConfig -VMname $TSEW -VMSize $TSEW_Size
        $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $TSEW -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
        $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -SKUs 2012-R2-Datacenter -Version "latest"
        $vm = Add-AzureRmVMNetworkInterface -vm $vm -Id $TSEW_NIC.Id
        $blobPath = "vhds/" + $TSEW + ".vhd"
        $osDiskUri = $TestSE_Sto.PrimaryEndpoints.Blob.ToString() + $blobPath
        $vm = Set-AzureRmVMOSDisk -VM $vm -Name $TSEW -VhdUri $osDiskUri -CreateOption FromImage
        New-AzureRmVM -ResourceGroupName $RG_Name -Location $PhyLoc -VM $vm

    }
if($SOProd_Bool)
    {
        $vm = New-AzureRmVMConfig -VMname $PSOS -VMSize $PSOS_Size
        $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $PSOS -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
        $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -SKUs 2012-R2-Datacenter -Version "latest"
        $vm = Add-AzureRmVMNetworkInterface -vm $vm -Id $PSOS_NIC.Id
        $blobPath = "vhds/" + $PSOS + ".vhd"
        $osDiskUri = $ProdSO_Sto.PrimaryEndpoints.Blob.ToString() + $blobPath
        $vm = Set-AzureRmVMOSDisk -VM $vm -Name $PSOS -VhdUri $osDiskUri -CreateOption FromImage
        New-AzureRmVM -ResourceGroupName $RG_Name -Location $PhyLoc -VM $vm

		$avName = Get-AzureRMAvailabilitySet -Name "PRODSOWEB" -ResourceGroupName $RG_Name
        $vm = New-AzureRmVMConfig -VMname $PSOW1 -VMSize $PSOW1_Size -AvailabilitySetId $avName
        $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $PSOW1 -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
        $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -SKUs 2012-R2-Datacenter -Version "latest"
        $vm = Add-AzureRmVMNetworkInterface -vm $vm -Id $PSOW1_NIC.Id
        $blobPath = "vhds/" + $PSOW1 + ".vhd"
        $osDiskUri = $ProdSO_Sto.PrimaryEndpoints.Blob.ToString() + $blobPath
        $vm = Set-AzureRmVMOSDisk -VM $vm -Name $PSOW1 -VhdUri $osDiskUri -CreateOption FromImage
        New-AzureRmVM -ResourceGroupName $RG_Name -Location $PhyLoc -VM $vm

        $vm = New-AzureRmVMConfig -VMname $PSOW2 -VMSize $PSOW2_Size -AvailabilitySetId $avName
        $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $PSOW2 -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
        $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -SKUs 2012-R2-Datacenter -Version "latest"
        $vm = Add-AzureRmVMNetworkInterface -vm $vm -Id $PSOW2_NIC.Id
        $blobPath = "vhds/" + $PSOW2 + ".vhd"
        $osDiskUri = $ProdSO_Sto.PrimaryEndpoints.Blob.ToString() + $blobPath
        $vm = Set-AzureRmVMOSDisk -VM $vm -Name $PSOW2 -VhdUri $osDiskUri -CreateOption FromImage
        New-AzureRmVM -ResourceGroupName $RG_Name -Location $PhyLoc -VM $vm

    }
if($SOTest_Bool)
    {
        $vm = New-AzureRmVMConfig -VMname $TSOS -VMSize $TSOS_Size
        $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $TSOS -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
        $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -SKUs 2012-R2-Datacenter -Version "latest"
        $vm = Add-AzureRmVMNetworkInterface -vm $vm -Id $TSOS_NIC.Id
        $blobPath = "vhds/" + $TSOS + ".vhd"
        $osDiskUri = $TestSO_Sto.PrimaryEndpoints.Blob.ToString() + $blobPath
        $vm = Set-AzureRmVMOSDisk -VM $vm -Name $TSOS -VhdUri $osDiskUri -CreateOption FromImage
        New-AzureRmVM -ResourceGroupName $RG_Name -Location $PhyLoc -VM $vm

        $vm = New-AzureRmVMConfig -VMname $TSOW -VMSize $TSOW_Size
        $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $TSOW -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
        $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -SKUs 2012-R2-Datacenter -Version "latest"
        $vm = Add-AzureRmVMNetworkInterface -vm $vm -Id $TSOW_NIC.Id
        $blobPath = "vhds/" + $TSOW + ".vhd"
        $osDiskUri = $TestSO_Sto.PrimaryEndpoints.Blob.ToString() + $blobPath
        $vm = Set-AzureRmVMOSDisk -VM $vm -Name $TSOW -VhdUri $osDiskUri -CreateOption FromImage
        New-AzureRmVM -ResourceGroupName $RG_Name -Location $PhyLoc -VM $vm
    }


#Add to LB#

if($SEProd_Bool)
	{
	$PSEW1_NIC.IpConfigurations[0].LoadBalancerBackendAddressPools=$SE_BEAddressPool
	$PSEW2_NIC.IpConfigurations[0].LoadBalancerBackendAddressPools=$SE_BEAddressPool
}
if($SOProd_Bool)
	{
	$PSOW1_NIC.IpConfigurations[0].LoadBalancerBackendAddressPools=$SO_BEAddressPool
	$PSOW2_NIC.IpConfigurations[0].LoadBalancerBackendAddressPools=$SO_BEAddressPool
}



############
#Data Disks#
############

if($SEProd_Bool)
    {
		##PROD SE SQL##

        $diskSize = 1023
		$diskLabel = $Acro + "-PRODSESQL01-disk-1"
		$diskName = $Acro + "-PRODSESQL01-disk-1"
		$storageAcc = Get-AzureRMStorageAccount -ResourceGroupName $RG_Name -StorageAccountName $ProdSESto
		$vm = Get-AzureRMVM -ResourceGroupName $RG_Name -Name $PSES 
		$vhdURI = $storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $diskName + ".vhd"
		Add-AzureRMVMDataDisk -VM $vm -Name $diskLabel -DiskSizeInGB $diskSize -VhdURI $vhdURI -CreateOption Empty

    }
if($SETest_Bool)
    {
		##Test SE SQL

		$diskSize = 1023
		$diskLabel = $Acro + "-TESTSESQL01-disk-1"
		$diskName = $Acro + "-TESTSESQL01-disk-1"
		$storageAcc = Get-AzureRMStorageAccount -ResourceGroupName $RG_Name -StorageAccountName $TestSESto
		$vm = Get-AzureRMVM -ResourceGroupName $RG_Name -Name $TSES 
		$vhdURI = $storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $diskName + ".vhd"
		Add-AzureRMVMDataDisk -VM $vm -Name $diskLabel -DiskSizeInGB $diskSize -VhdURI $vhdURI -CreateOption Empty

    }
if($SOProd_Bool)
    {
		##Prod SO SQL##

		$diskSize = 1023
		$diskLabel = $Acro + "-PRODSOSQL01-disk-1"
		$diskName = $Acro + "-PRODSOSQL01-disk-1"
		$storageAcc = Get-AzureRMStorageAccount -ResourceGroupName $RG_Name -StorageAccountName $ProdSOSto
		$vm = Get-AzureRMVM -ResourceGroupName $RG_Name -Name $PSOS 
		$vhdURI = $storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $diskName + ".vhd"
		Add-AzureRMVMDataDisk -VM $vm -Name $diskLabel -DiskSizeInGB $diskSize -VhdURI $vhdURI -CreateOption Empty

    }
if($SOTest_Bool)
    {
		##Test SE SQL##

		$diskSize = 1023
		$diskLabel = $Acro + "-TESTSOSQL01-disk-1"
		$diskName = $Acro + "-TESTSOSQL01-disk-1"
		$storageAcc = Get-AzureRMStorageAccount -ResourceGroupName $RG_Name -StorageAccountName $TestSOSto
		$vm = Get-AzureRMVM -ResourceGroupName $RG_Name -Name $TSOS 
		$vhdURI = $storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $diskName + ".vhd"
		Add-AzureRMVMDataDisk -VM $vm -Name $diskLabel -DiskSizeInGB $diskSize -VhdURI $vhdURI -CreateOption Empty
    }

