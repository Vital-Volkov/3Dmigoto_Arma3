# 3Dmigoto_Arma3
3Dmigoto Arma3 fix with custom eye priority S3D settings.

![Arma3_sighting](https://github.com/Vital-Volkov/3Dmigoto_Arma3/blob/main/Arma3_sighting.png)
## What made
Custom unsymmetric(eye priority for sighting) S3D settings based on my UserIPD/VirtualIPD system to replace NV Separation/Convergence 3DVision settings.

## How to use
- Set 3DVision Separation/Convergence both to zero.
Even at minimal Separation=1 Convergence=0(hold hotkey (default Ctrl+F5) ~10 seconds to get absolute zero) it creates some micro depth so I don't find how to turn the NV setting to absolute zero flat 2D before using my custom S3D settings.
- Open d3dx.ini and set critical vars in millimeters to get correct S3D like in real life:
  <b>global $userIPD = ?</b> this is your interpupillary eyes distance. If you don't know your size you can measure using a ruler and mirror.
  Hold ruler on mirror and shift position such that using left eye you see 0mm in center of left pupil and stay still close left open right eye and in center of right  pupil you will see your userIPD. If you don't shift while you see 0mm in the left eye and swap left close right open then you get enough precision but you can set it a little lower if not sure and this better for health feel than oversize which causes overshoot eyes parallel direction when you look at max depth like stars. But if you set userIPD much lower than real size then you get not realistic shallow max depth. In real life any creature with any IPD gets parallel direction  eyes looking at infinitely far objects like stars so when you see at screen to get the same result like in real life userIPD must be set correctly for each user.
  As $userIPD explicitly in mm instead of to screen size ratio then to match real mm global <b>$viewportWidth = ?</b> must also be set correctly so it you playing game fullscreen then it's width of screen which can be measured by ruler but better to know tech specs of PPI(Pixels Per Inch) or pixel step so you can calculate precision size of viewport.
  
  For example 23"diagonal LG D2342P monitor is 1920 / 96PPI = 20"width * 25.4mmPerInch = 508mm or pixel step 0.264mm * 1920 = 506.88mm
  If you playing not full screen replace native 1920 screen width with viewport width or if you use not native pixel to pixel scale like I use fullscreen 1280x720 HD3D NV quad buffer use how many viewport takes real screen pixels for calculation not scaled game renderer resolution or just measure viewport by ruler.
  
  <b>global $virtualIPD = ?</b> set it the same as $userIPD for realistic view or set it for example $userIPD 66mm * 10 = 660mm to see the game world as a toy.

  <b>$renderSideForRightEye = -1</b> to swap which eye will be rendered on NV left side -1 or right side 1. I have swapped left/right on the HD3D quad buffer so with -1 I get correct eye order and also S3D compass laying perfect on 2D map but with 1 it slightly levitates over map. Maybe you get the same so better swap using 3dvision2sbs post shader by F11 hotkey.

  <b>$GUIDepth = 1</b> set GUI depth for game start with. Valid any between 0 to get GUI depth 0 like regular 2D or 1 to move GUI to max depth set by <b>$userIPD</b>.
  You can use hotkeys <b><</b> and <b>></b> to set GUI depth with 0.1 step while in game and also pressing <b>M</b> toggle it to 0 for 2D map and back so you need to press <b>M</b> yourself when map is opened not via hotkey to avoid stretching some map elements. Press <b>T</b> to set GUI to depth sampled from depth map useful for optics with range measure.

  <b>$stereo3DPIPDisplaysInGame = 1</b> set airhud depth for game start with. Valid toggle 0 (original airhud on 3D plane not correctly close to eyes) or 1 (at max depth like in real life) but problem that Arma3 use same textures for airhud and 3D panels so toggle it by hotkey <b>/</b> if you need look at panel.

  <b>$stereo3DPIPDisplaysInGame = 1</b> valid toggle 1 displays in Arma3 will be stereoscopic or 0 2D.

  <b>$millimetersPerGameUnit = 1000</b> connection between settings in mm and game units. Arma3 1 unit of game world is 1m or 1000mm so no need to change it but if you use this d3dx.ini template for another game with different game world size units it must be set accordingly.
  
## What is fixed
- NV S3D settings were replaced with my custom independent UserIPD and VirtualIPD so zoom now is correct with constant stereo base.
- Non symmetric VirtualIPD allows eye priority sighting with automatic right-left with stance change.
- 2D sprites like Sun, light halos moved to correct depth using original depth map from dominant eye without VirtualIPD applied which is not possible with original NV settings.
- FSAA depth map resolved with custom shader so now any FSAA2-8x can be used.
- Object contours over sky caused by incorrect read of depth map.
- The S3D mouse now correctly reads the original texture.
- Compass, Watch, Gas Analyzer keep near screen depth position independent of S3D settings.
- Water reflections now are perfect S3D.
- Water edge as white line from under water caused by incorrectly disassembled shader fixed in original asm.
- Caustics 2D screen space post process pixel shader now S3D.
- Airhud now can be moved to max depth where it IRL and back by hotkey.
- god rays or sun shafts.
- Mirrors and PIP displays (can be set as 2D in d3dx.ini) now S3D.
- 2D GUI processed at edges (UV shifted instead of vertices) to avoid edges detaching if GUI moved to depth by hotkey or by sampled from depth map with range finder
  while 3D GUI elements like editor model bounding boxes or bullet lines keep correct S3D.
- And most interesting is collimator now like IRL. To fix it I implemented UV calculation from scratch (what GPU do under hood) but for vertices before VirtualIPD shift instead of current already shifted vertices so as result mesh frame can be moved to any position but collimator mark always stays still at max depth. You can use this hack when you need to shift vertices as usual but keep texture at original position untouched on same screen pixels without any deformation caused by new 3D vertex positions.
- performance optimized and more...

It was a great challenge and learning curve how shaders work. Thanks to all creators of the 3Dmigoto and S3D community for such powerfull instruments. 
Using it I actually implemented my S3D system in Arma3 and now playing it is awesome. Enjoy!

## 💰 [Donate](https://donatr.ee/wital?utm_source=copy&utm_medium=share)
