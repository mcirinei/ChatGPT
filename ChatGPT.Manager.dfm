object Manager: TManager
  Height = 480
  Width = 640
  object ActionListMain: TActionList
    Left = 48
    Top = 16
    object ShowShareSheetAction: TShowShareSheetAction
      Category = 'Media Library'
      OnBeforeExecute = ShowShareSheetActionBeforeExecute
    end
  end
end
