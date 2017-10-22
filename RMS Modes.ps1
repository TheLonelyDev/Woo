# Path to your AoE2 installation, if you comment this out then you will disable the feature of saving to your AoE2 folder.
$strAoEPath =  "D:\Program Files\AoE2"

# Scan the sub directories for "projects"
Get-ChildItem -Recurse -Directory | ForEach-Object { 
    $objJSON = Get-Content ( "$($_.FullName)\rms.info.json" ) | ConvertFrom-Json

    # If the strAoEPath exists then test if the same file exists there and compare dates, if that file is newer then copy said file to here
    if ( Get-Variable strAoEPath -ErrorAction SilentlyContinue )
    {
        if ( Test-Path ( $strAoEPath + "\Random\" + $objJSON.Meta.File  + ".rms" ) )
        {
            if ( ( [datetime]( Get-ItemProperty -Path ( "$($_.FullName)\" + $objJSON.Meta.File  + ".rms" ) -Name LastWriteTime ).lastwritetime ) -lt ( [datetime]( Get-ItemProperty -Path ( $strAoEPath + "\Random\" + $objJSON.Meta.File  + ".rms" ) -Name LastWriteTime ).lastwritetime ) )
            {
                Copy-Item ( $strAoEPath + "\Random\" + $objJSON.Meta.File  + ".rms" ) ( "$($_.FullName)" )
            }
        }
    } 

    $strBaseFile = ( Get-Content ( "$($_.FullName)\" + $objJSON.Meta.File  + ".rms" ) ) -Join "`n"
    
    foreach ( $obj in $objJSON.Data ) 
    {
        $strToWrite = "" 
        foreach ( $str in $obj )
        {
            $strToWrite += ( "#define " + ( $str ).ToUpper( ) + ( $objJSON.Meta.DataAppend ).ToUpper( ) + "`r`n" ) ;
        } 

        New-Item -Force -Type file -Path "$($_.FullName)" -Name ( ( $objJSON.Meta.Prefix + $objJSON.Meta.Name + "." + ( [string]$obj ).ToUpper( ) ).trim( "." ) + ".rms" ) -Value ( $strToWrite  +  $strBaseFile )
        
        # Check if strAoEPath exists, if not then do nothing.
        if ( Get-Variable strAoEPath -ErrorAction SilentlyContinue )
        {
            New-Item -Force -Type file -Path ( $strAoEPath + "\Random" ) -Name ( ( $objJSON.Meta.Prefix + $objJSON.Meta.Name + "." + ( [string]$obj ).ToUpper( ) ).trim( "." ) + ".rms" ) -Value ( $strToWrite  +  $strBaseFile )
        }    
    }
}



# Each project file needs atleast 2 files

# rms.info.json and your rms file (see below to define it's name)

<#
{
    "Data": 
    [
      [ ] ,
      [ "DEFINE_1" ] ,
      [ "DEFINE_2" ] ,
      [ "DEFINE_1", "DEFINE_2" ] ,
    ],
    "Meta": 
    {
      "Name" : "The name that will be used after the prefix, eg Islands" ,
      "File" : "The name of the rms (base) file inside the directory devIslands" ,
      "Prefix" : "A prefix to prevent file collisions, leave empty if you want none. Please note to include your own . or @ etc, eg TLD. or TLD@" ,
      "DataAppend" : "If you do not feel like typing a lot in Data and every word is suffixed with something eg _MODE then enter _MODE here"
    }
  }


More concrete example:
  {
    "Data": 
    [
      [ ] ,
      [ "NOMAD" ] ,
      [ "XRES" ] ,
      [ "NOMAD", "XRES" ]
    ],
    "Meta": 
    {
      "Name" : "HolyForest" ,
      "File" : "devHolyForest" ,
      "Prefix" : "TLD." ,
      "DataAppend" : "_MODE"
    }
  }

Output files have this on the top of the file
    TLD.HolyForest.rms

    TLD.HolyForest.NOMAD.rms
        #define NOMAD_MODE

    TLD.HolyForest.XRES.rms
        #define XRES_MODE

    TLD.HolyForest.NOMAD XRES.rms
        #define NOMAD_MODE
        #define XRES_MODE
#>