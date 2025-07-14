using System;

namespace TruvideoVideoiOS
{ 
    public enum VideoFrameRate: long {
        TwentyFourFps = 0 ,
        TwentyFiveFps = 1,
        ThirtyFps = 2,
        FiftyFps = 3,
        SixtyFps = 4
     }
    
  
    public enum VideoRequestStatus : long
    {
        Cancelled,
        Error,
        Idle,
        Processing,
        Complete
    }

  
    public enum VideoRequestType : long
    {
        Encode,
        Merge,
        Concat
    }

}


