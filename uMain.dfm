object SampleService: TSampleService
  OldCreateOrder = False
  DisplayName = 'SampleService'
  OnExecute = ServiceExecute
  OnPause = ServicePause
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 150
  Width = 215
end
