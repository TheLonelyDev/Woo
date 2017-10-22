#Wooo, a scripting language on top of RMS to make map development faster.

$arrJSON                    =   Get-Content ( "info.json" ) | ConvertFrom-Json ;

Function ShowToast
{
    param ( [string]$strTitle ) ;

    $ErrorActionPreference  =   "Stop"

    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null ;

    $objTemplate            =   [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent( [Windows.UI.Notifications.ToastTemplateType]::ToastText01 ) ;

    $strXML                 =   [xml]$objTemplate.GetXml( ) ;
    $strXML.GetElementsByTagName( "text" ).AppendChild( $strXML.CreateTextNode( $strTitle ) ) > $null ;


    $xml                    =   New-Object Windows.Data.Xml.Dom.XmlDocument ;
    $xml.LoadXml( $strXML.OuterXml ) ;

    $objToast               =   [Windows.UI.Notifications.ToastNotification]::new( $xml ) ;
    $objToast.Tag           =   "Woo Compiler" ;
    $objToast.Group         =   "Woo Lang" ;
    $objToast.ExpirationTime=   [DateTimeOffset]::Now.AddMinutes( 6 ) ;
    #$toast.SuppressPopup = $true

    $objNotifier            =   [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier( "Woo Lang" ) ;
    $objNotifier.Show( $objToast ) ;
}

Function XRND
{
    param( [string]$strInput ) ;

    $strOutput              =   $strInput ;
    $objXRND                =   [regex]::matches( $strOutput, "(?:([A-Za-z0-9_#]*.*?)xrnd{([^;]*)};)", [System.Text.RegularExpressions.RegexOptions]::MultiLine ) ;

    foreach ( $obj in $objXRND )
    {
        
        $strFull            =   $obj.groups[ 0 ] ;
        $strFunction        =   ( [string]$obj.groups[ 1 ] ).Trim( ) ;
        $strRandom          =   ( [string]$obj.groups[ 2 ] ).Trim( ) ;

        $boolPreDefined     =   ( $strRandom -Like "*|*" ) ;

        $arrRandom          =   $null ;
        $arrPreDefined      =   $null ;

        if ( $boolPreDefined )
        {
            $arrPreDefined  =   ( ( $strRandom -Split "\|" )[ 1 ] ) -Split "&" ;
            $arrRandom      =   ( ( $strRandom -Split "\|" )[ 0 ] ) -Split "&" ;
        }
        else
        {
            $arrRandom      =   $strRandom -Split "&" ;
        }

        $intTotal           =   $arrRandom.Count ;
        $intNormalPercent   =  [math]::floor( 100 / $intTotal ) ;

        $strToReplace       =   "start_random" + "`r`n"

        $intCurrent         =   0 ;

        $strSplit           =   $null ;

        if ( ( $strFunction -Split "`n" ).Count -gt 1 )
        {
            $strSplit       =   "`r`n" ;
        }
        else
        {
            $strSplit       =   " " ;
        }

        if ( $boolPreDefined )
        {
            foreach ( $str in $arrRandom )
            {
                
                if ( ( ( $str.Trim( ) ) -eq "" ) -And ( $strSplit -eq " " ) )
                {
                    $strFunction    =   "" ;
                }

                $strToReplace += ( "percent_chance " +  $arrPreDefined[ $intCurrent ]  + $strSplit + $strFunction + " " + $str + "`r`n" ) ;

                $intCurrent++ ;
            }
        }
        else
        {
            foreach ( $str in $arrRandom )
            {
                if ( ( ( $str.Trim( ) ) -eq "" ) -And ( $strSplit -eq " " ) )
                {
                    $strFunction    =   "" ;
                }

                $strToReplace += ( "percent_chance " +  $intNormalPercent + $strSplit + $strFunction + " " + $str + "`r`n" ) ;

                $intCurrent++ ;
            }       
        }

        $strToReplace += "end_random" ;

        $strOutput           =   $strOutput.Replace( $strFull, $strToReplace ) ;
    }

    return $strOutput ;
}

Function AndOr
{
    param( [string]$strInput ) ;

    $strOutput              =   $strInput ;
    $objIF                  =   [regex]::matches( $strInput, "(?:(\bif\b(.*?)(?=\n)(.*?)(?=\belse\b|\bendif\b)(.*?)\bendif\b))", [System.Text.RegularExpressions.RegexOptions]::SingleLine ) ;

    foreach ( $obj in $objIF )
    {
        $strFull            =   $obj.groups[ 1 ] ;
        $strStatement       =   $obj.groups[ 2 ] ;
        $strIfBlock         =   $obj.groups[ 3 ] ;
        $strElseBlock       =   $obj.groups[ 4 ] ;

        $strToReplace       =   $null ;

        if ( $strStatement -Like "*||*" )
        {
            $arrLabels      =   ( $strStatement -Split( "\|\|" ) ).Trim( ) ;

            foreach ( $strLabel in $arrLabels )
            {
                $strToReplace   += "`r`nif " + $strLabel + $strIfBlock + "else`r`n" + $strElseBlock + "`r`nendif`r`n" ;        
            }        
        }
        elseif ( $strStatement -LIKE "*&&*" )
        {
            $arrLabels      =   ( ( $strStatement -Split( "&&" ) ).Trim( ) ) ;
            [array]::Reverse( $arrLabels ) ;

            $int            =   0 ;

            foreach ( $strLabel in $arrLabels )
            {
                if ( $int -eq 0 )
                {
                    $strToReplace= "`r`nif " + $strLabel + $strIfBlock + "else`r`n" + $strElseBlock + "`r`nendif`r`n" ;
                }
                else
                {
                    $strToReplace= "`r`nif " + $strLabel + "" + $strToReplace + "`r`nelse`r`nendif`r`n" ;        
                }

                $int++ ;
            }   
        }
        else
        {
            continue ;
        }
        
        $strOutput          =   $strOutput.Replace( $strFull, $strToReplace ) ;
    }

    return $strOutput ;
}

Function Template
{
    param( [string]$strInput ) ;

    $strOutput              =   $strInput ;
    $objTemplate            =   [regex]::matches( $strOutput, "(?:(\bcreate_template\b(.*?)(?=\n)(.*?)(?=\}\;)};))", [System.Text.RegularExpressions.RegexOptions]::SingleLine ) ;
    
    foreach ( $obj in $objTemplate )
    {
        $strFull            =   $obj.groups[ 1 ] ;
        $strWord            =   ( [string]$obj.groups[ 2 ] ).Trim( ) ;
        $strBlock           =   ( [string]$obj.groups[ 3 ] ).Trim( ).Trim( "{" ) ;     

        $strOutput          =   $strOutput.Replace( $strFull, '' ) ;

        $strOutput          =   $strOutput.Replace( " " + $strWord, $strBlock ) ;
    }

    return $strOutput ;
}

Function Optimise
{
    param( [string]$strInput ) ;

    $strInput               =   $strInput -Replace "(?:\/\*(.*?)\*\/)", "" ;
    $strOutput              =   "" ;

    foreach ( $strLine in $( $strInput -Split "`n" ) )
    {
        $str                =   ( $strLine.Trim( ) ) ;

        if ( $str -eq "" )
        {

        }
        elseif ( $str -eq "{" -Or $str -eq "}" )
        {
            $strOutput      =  $strOutput.Substring( 0, $strOutput.Length - 1 ) + " " + $str + "`n" ;
        }
        else
        {
            $strOutput  +=  $str + "`n" ;
        }
    }

    $strOutput              =   ( ( $strOutput -Replace "[\t]{1,}"," " ).Trim( ) ) -Replace "[ ]{2,}"," " ;

    return $strOutput ;
}

$arrModes                   =   New-Object System.Collections.ArrayList ;
Function Modes
{
    param( [string]$strInput ) ;

    $strOutput              =   $strInput ;
    $objModes               =   [regex]::matches( $strOutput, "(?:(#pragma(.*)(?=;);))" ) ;

    foreach ( $obj in $objModes )
    { 
        $strFull            =   $obj.groups[ 1 ] ;
        $strMode            =   ( [string]$obj.groups[ 2 ] ).Trim( ) ;

        [void]$arrModes.Add( $strMode ) ;

        $strOutput          =   $strOutput.Replace( $strFull, "" ) ;

        #$strFull            =   $obj.groups[ 0 ] ;
        #$strBlock           =   ( [string]$obj.groups[ 1 ] ).Trim( ) ;
        #$strSuffix          =   ( $strBlock -Split "|" )[ 1 ].Trim( ) ;
        
        #foreach ( $strMode in $( ( ( ( $strBlock -Split "|" )[ 0 ].Trim( ) ) -Split "&" ).Trim( ) ) )
        #{
        #    $arrModes.Add( $strMode + $strSuffix ) ;
        #}

        #$strOutput          =   $strOutput.Replace( $strFull, '' ) ;
    }

    return $strOutput ;  
}

$strMainPath                =   $arrJSON.Publish[ 0 ] ;
Function Compile
{
    param( $_ ) ;
    
    if ( Test-Path ( $strMainPath + "/" + ( $_.Name ) ) )
    {
        if ( ( [datetime]( Get-ItemProperty -Path ( ( $_.FullName ) ) -Name LastWriteTime ).lastwritetime ) -lt ( [datetime]( Get-ItemProperty -Path ( $strMainPath + "/" + ( $_.Name ) ) -Name LastWriteTime ).lastwritetime ) )
        {
            return ;
        }
    }

    ShowToast( "Compiling " + ( $_.Name ) ) ;
    $strInput               =   ( Get-Content ( $_.FullName ) ) -Join "`n" ;    

    foreach ( $strFeature in $arrJSON.Features )
    {
        switch ( $strFeature )
        {
            "MODES"
            {
                $strInput   =   Modes( $strInput ) ;
            }
            "XRND"
            {
                $strInput   =   XRND( $strInput ) ;
            }
            "ANDOR"
            {
                $strInput   =   AndOr( $strInput ) ;
            }
            "TEMPLATE"
            {
                $strInput   =   Template( $strInput ) ;
            }
            "OPTIMISE"
            {
                $strInput   =   Optimise( $strInput ) ;
            }
        }
    }

    if ( $arrJSON.Header -ne "" )
    {
        $strInput           =   "/**`r`n" + $arrJSON.Header + "`r`n**/`r`n`r`n" + $strInput ; 
    }

    if ( $arrJSON.Footer -ne "" )
    {
        $strInput           +=   "`r`n`r`n/**`r`n" + $arrJSON.Footer + "`r`n**\`r`n" ; 
    }

    if ( $arrModes.Length -gt 0 )
    {
        foreach ( $strMode in $arrModes )
        {
            $strOut         =   "" ;
            foreach ( $strDef in $( $strMode -Split " " ) )
            {
                $strOut     +=   ( "#define " + $strDef + "`n" ) ;
            }   

            $strOut         =   $strOut + $strInput ;

            foreach ( $strPath in $arrJSON.Publish )
            {
                New-Item -Force -Type file -Path $strPath -Name ( ( $_.Name.Insert( $_.Name.LastIndexOf( "." ), ( "." + $strMode ) ) ) ) -Value ( $strOut ) ;
            }
        }
    }
    else
    {
        foreach ( $strPath in $arrJSON.Publish )
        {
            New-Item -Force -Type file -Path $strPath -Name ( ( $_.Name ) ) -Value ( $strInput ) ;
        }
    }

    ShowToast( "Finished compiling " + ( $_.Name ) ) ;
}

Function RawCompile
{
    Start-Process -FilePath ".\Woo Compiler.bat.lnk" ;
    Stop-Process -Id $PID ;
}

Function Register-Watcher 
{
    param ( $strPath )

    $strFilter      =   "*.rms" ;

    $objWatcher     =   New-Object IO.FileSystemWatcher $strPath, $strFilter -Property @{ 
        IncludeSubdirectories       =   $false
        EnableRaisingEvents         =   $true
    }

    Register-ObjectEvent $objWatcher "Changed" -Action $( $function:RawCompile ) ;   
}

Register-Watcher ( [string]( Get-Location ) + "\Woo Source" ) ;

Get-ChildItem ( [string]( Get-Location ) + "\Woo Source" ) -File | ForEach-Object {
    Compile( ( $_ ) ) ;
}

while ( $true ) { sleep 1 } 
