$Input | Measure-Object -Line -Word -Character
function MeasureFromPipelineInput {

    param ( [Parameter(ValueFromPipeline=$true)] $Text )

    Begin {}
    Process {
       $Text | Measure-Object -Line -Word -Character
    }
    End {}
    
}

#MeasureFromPipelineInput
