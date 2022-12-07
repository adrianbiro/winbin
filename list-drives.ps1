	Get-PSDrive -PSProvider FileSystem |
          format-table -property Name,Root,
               @{n="Used (GB)";
                    e={[math]::Round($_.Used/1GB,1)}},
               @{n="Free (GB)";
                    e={[math]::Round($_.Free/1GB,1)}}
