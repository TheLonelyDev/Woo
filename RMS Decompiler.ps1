#Wooo, a scripting language on top of RMS to make map development faster.

$strInput 			= 	( Get-Content "Original.rms" ) -Join "`n" ;

$strNull            =   ( "NULL" + ( Get-Date ).Ticks ) + "{}"

$objXRND            =   [regex]::matches( $strInput, "(?:\bstart_random\b(.*?)\bend_random\b)", [System.Text.RegularExpressions.RegexOptions]::SingleLine ) ;

foreach ( $obj in $objXRND )
{
    $strFull        =   $obj.groups[ 0 ] ;

    $objRX          =   [regex]::matches( $strFull, "(?:\bpercent_chance\b.*?(?=\d+)(.*?)(?=\D+)(.*?)(?=\bpercent_chance|end_random\b))", [System.Text.RegularExpressions.RegexOptions]::SingleLine ) ;

    $strMainBase    =   $null ;
    $arrExtra       =   New-Object System.Collections.ArrayList ;
    $arrWeight      =   New-Object System.Collections.ArrayList ;
    
    $boolAbort      =   $false ;
    foreach ( $objPC in $objRX )
    {
        $intPC      =   ( [string]$objPC.groups[ 1 ] ).Trim( ) ;
        $str        =   ( [string]$objPC.groups[ 2 ] ).Trim( ) ;

        $arrBase    =   ( $str -Split " " ) ;
        $strBase    =   $arrBase[ 0 ] ;

        $arrBase[ 0 ]=  $null ;

        $strExtra   =  ( $arrBase -Join " " ).Trim( ) ;

        if ( $strMainBase -eq $null )
        {
            $strMainBase=   $strBase ;
        }
        elseif ( $strMainBase -ne $strBase )
        {
            $boolAbort = $true ;
            continue ;
        }

        if ( $strExtra -eq "" )
        {
            if ( $arrExtra[ 0 ] -Like "*{*" )
            {
                $strExtra=   $strNull ;
            }
        }
        elseif ( $strExtra -NotLike "*{*" )
        {
            if ( ( $strExtra -split "`n" ).Count -gt 1 )
            {
                $boolAbort= $true ;
                continue ;
            }
        }
        
        $arrExtra.Add( $strExtra ) ;
        $arrWeight.Add( $intPC ) ;
    }

    if ( $boolAbort -eq $true )
    {
        
    }
    else
    {
        $strInput       =   $strInput.Replace( $strFull, ( $strMainBase + ( " xrnd{" + ( $arrExtra -Join "&" ) + "|" + ( $arrWeight -Join "&" ) + "};" ) ) ) ;
    }
}

New-Item -Force -Type file -Name ( "Wooo.rms" ) -Value ( $strInput ) ;
