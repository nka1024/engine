package flixel.system.input;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.Lib;
import flash.ui.Mouse;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.system.replay.MouseRecord;
import flixel.util.FlxPoint;

/**
* This class helps contain and track the mouse pointer in your game.
* Automatically accounts for parallax scrolling, etc.
*/
class FlxMouse extends FlxPoint implements IFlxInput
{
	// possible values for field '_current'
	// 2 - just pressed
	// 1 - pressed
	// 0 - released
	// -1 - just released
	// -2 - fast press and release

	/**
	 * Current "delta" value of mouse wheel. If the wheel was just scrolled up, it will have a positive value. If it was just scrolled down, it will have a negative value. If it wasn't just scroll this frame, it will be 0.
	 */
	public var wheel:Int;
	/**
	 * Current X position of the mouse pointer on the screen.
	 */
	public var screenX:Int;
	/**
	 * Current Y position of the mouse pointer on the screen.
	 */
	public var screenY:Int;
	/**
	 * Property to check if the cursor is visible or not.
	 */
	public var visible(get_visible, null):Bool;
	/**
	 * Helper variable for tracking whether the mouse was just pressed or just released.
	 */
	private var _current:Int;

	#if (FLX_MOUSE_ADVANCED && !js)
	/**
	 * Helper variable for tracking whether the right mouse button was just pressed or just released.
	 */
	private var _currentRight:Int;
	/**
	 * Helper variable for tracking whether the left mouse button was just pressed or just released.
	 */
	private var _currentMiddle:Int;
	#end

	/**
	 * Helper variable for tracking whether the mouse was just pressed or just released.
	 */
	private var _last:Int;
	/**
	 * A display container for the mouse cursor.
	 * This container is a child of FlxGame and sits at the right "height".
	 */
	public var cursorContainer:Sprite;
	/**
	 * Don't update cursor unless we have to (this is essentially a "visible" bool, so we avoid checking the visible property in the Sprite which is slow in cpp).
	 */
	private var _updateCursorContainer:Bool;
	/**
	 * This is just a reference to the current cursor image, if there is one.
	 */
	private var _cursor:Bitmap;
	
	private var _cursorBitmapData:BitmapData;

	/**
	 * Helper variables for recording purposes.
	 */
	private var _lastX:Int;
	private var _lastY:Int;
	private var _lastWheel:Int;
	private var _point:FlxPoint;
	private var _globalScreenPosition:FlxPoint;
	/**
	 * Tells flixel to use the default system mouse cursor instead of custom Flixel mouse cursors.
	 * @default false
	 */
	public var useSystemCursor(default, set_useSystemCursor):Bool;

	/**
	 * Constructor.
	 */
	public function new(CursorContainer:Sprite)
	{
		super();
		cursorContainer = CursorContainer;
		cursorContainer.mouseChildren = false;
		cursorContainer.mouseEnabled = false;
		_lastX = screenX = 0;
		_lastY = screenY = 0;
		_lastWheel = wheel = 0;
		_current = 0;
		_last = 0;
		_cursor = null;
		_point = new FlxPoint();
		_globalScreenPosition = new FlxPoint();
		useSystemCursor = false;
		
		Lib.current.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		Lib.current.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		Lib.current.stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		#if (FLX_MOUSE_ADVANCED && !js)
		Lib.current.stage.addEventListener(untyped MouseEvent.RIGHT_MOUSE_DOWN, onMouseDownRight);
		Lib.current.stage.addEventListener(untyped MouseEvent.RIGHT_MOUSE_UP, onMouseUpRight);
		Lib.current.stage.addEventListener(untyped MouseEvent.MIDDLE_MOUSE_DOWN, onMouseDownMiddle);
		Lib.current.stage.addEventListener(untyped MouseEvent.MIDDLE_MOUSE_UP, onMouseUpMiddle);
		#end
	}

	/**
	 * Internal event handler for input and focus.
	 * @param FlashEvent Flash mouse event.
	 */
	private function onMouseDown(FlashEvent:MouseEvent):Void
	{
		#if !FLX_NO_DEBUG
		if(FlxG._game._debuggerUp)
		{
			if (FlxG._game._debugger.hasMouse)
			{
				return;
			}
			if (FlxG._game._debugger.watch.editing)
			{
				FlxG._game._debugger.watch.submit();
			}
		}
		#end
		
		#if FLX_RECORD
		if(FlxG._game._replaying && (FlxG._game._replayCancelKeys != null))
		{
			var replayCancelKey:String;
			var i:Int = 0;
			var l:Int = FlxG._game._replayCancelKeys.length;
			while(i < l)
			{
				replayCancelKey = FlxG._game._replayCancelKeys[i++];
				if ((replayCancelKey == "MOUSE") || (replayCancelKey == "ANY"))
				{
					if(FlxG._game._replayCallback != null)
					{
						FlxG._game._replayCallback();
						FlxG._game._replayCallback = null;
					}
					else
					{
						FlxG.vcr.stopReplay();
					}
					break;
				}
			}
			return;
		}
		#end
		
		if (_current > 0) _current = 1;
		else _current = 2;
	}

	/**
	 * Internal event handler for input and focus.
	 * @param FlashEvent Flash mouse event.
	 */
	private function onMouseUp(FlashEvent:MouseEvent):Void
	{
		#if !FLX_NO_DEBUG
		if ((FlxG._game._debuggerUp && FlxG._game._debugger.hasMouse) #if FLX_RECORD|| FlxG._game._replaying#end)
		{
			return;
		}
		#end
		
		if (_current > 0)
		{
			_current = -1;
		}
		else if (_current == -2)
		{
			_current == -2;
		}
		else
		{
			_current = 0;
		}
	}

	/**
	 * Internal event handler for input and focus.
	 * @param FlashEvent Flash mouse event.
	 */
	private function onMouseWheel(FlashEvent:MouseEvent):Void
	{
		#if !FLX_NO_DEBUG
		if ((FlxG._game._debuggerUp && FlxG._game._debugger.hasMouse) #if FLX_RECORD|| FlxG._game._replaying #end)
		{
			return;
		}
		#end
		
		wheel = FlashEvent.delta;
	}

	#if (FLX_MOUSE_ADVANCED && !js)
	private function onMouseDownRight(FlashEvent:MouseEvent):Void
	{
		if (_currentRight > 0) _currentRight = 1;
		else _currentRight = 2;
	}

	private function onMouseUpRight(FlashEvent:MouseEvent):Void
	{
		if (_currentRight > 0)
		{
			_currentRight = -1;
		}
		else if (_currentRight == -2)
		{
			_currentRight == -2;
		}
		else
		{
			_currentRight = 0;
		}
	}

	private function onMouseDownMiddle(FlashEvent:MouseEvent):Void
	{
		if (_currentMiddle > 0) _currentMiddle = 1;
		else _currentMiddle = 2;
	}

	private function onMouseUpMiddle(FlashEvent:MouseEvent):Void
	{
		if (_currentMiddle > 0)
		{
			_currentMiddle = -1;
		}
		else if (_currentMiddle == -2)
		{
			_currentMiddle == -2;
		}
		else
		{
			_currentMiddle = 0;
		}
	}
	#end

	/**
	 * Clean up memory.
	 */
	public function destroy():Void
	{
		cursorContainer = null;
		_cursor = null;
		_point = null;
		_globalScreenPosition = null;
		if (_cursorBitmapData != null)
		{
			_cursorBitmapData.dispose();
			_cursorBitmapData = null;
		}
	}

	/**
	 * Either show an existing cursor or load a new one.
	 * @param Graphic The image you want to use for the cursor.
	 * @param Scale Change the size of the cursor. Default = 1, or native size. 2 = 2x as big, 0.5 = half size, etc.
	 * @param XOffset The number of pixels between the mouse's screen position and the graphic's top left corner.
	 * @param YOffset The number of pixels between the mouse's screen position and the graphic's top left corner.
	 */
	public function show(Graphic:Dynamic = null, Scale:Float = 1, XOffset:Int = 0, YOffset:Int = 0):Void
	{
		_updateCursorContainer = true;
		cursorContainer.visible = true;
		if (Graphic != null)
		{
			load(Graphic, Scale, XOffset, YOffset);
		}
		else if (_cursor == null)
		{
			load();
		}
		if (useSystemCursor)
		{
			Mouse.show();
		}
	}

	/**
	 * Hides the mouse cursor
	 */
	inline public function hide():Void
	{
		_updateCursorContainer = false;
		cursorContainer.visible = false;
	}

	/**
	 * Read only, check visibility of mouse cursor.
	 */
	inline private function get_visible():Bool
	{
		return _updateCursorContainer;
	}

	/**
	 * Load a new mouse cursor graphic
	 * @param Graphic The image you want to use for the cursor.
	 * @param Scale Change the size of the cursor.
	 * @param XOffset The number of pixels between the mouse's screen position and the graphic's top left corner.
	 * @param YOffset The number of pixels between the mouse's screen position and the graphic's top left corner.
	 */
	public function load(Graphic:Dynamic = null, Scale:Float = 1, XOffset:Int = 0, YOffset:Int = 0):Void
	{
		if (_cursor != null)
		{
			cursorContainer.removeChild(_cursor);
		}
		
		if (Graphic == null)
		{
			Graphic = FlxAssets.imgDefaultCursor;
		}
		
		if (Std.is(Graphic, Class))
		{
			_cursor = Type.createInstance(Graphic, []);
		}
		else if (Std.is(Graphic, BitmapData))
		{
			_cursor = new Bitmap(cast(Graphic, BitmapData));
		}
		else if (Std.is(Graphic, String))
		{
			_cursor = new Bitmap(FlxAssets.getBitmapData(Graphic));
		}
		else
		{
			_cursor = new Bitmap(FlxAssets.getBitmapData(FlxAssets.imgDefaultCursor));
		}
		
		_cursor.x = XOffset;
		_cursor.y = YOffset;
		_cursor.scaleX = Scale;
		_cursor.scaleY = Scale;
		
		cursorContainer.addChild(_cursor);
	}

	/**
	 * Unload the current cursor graphic. If the current cursor is visible,
	 * then the default system cursor is loaded up to replace the old one.
	 */
	public function unload():Void
	{
		if(_cursor != null)
		{
			if (cursorContainer.visible)
			{
				load();
			}
			else
			{
				cursorContainer.removeChild(_cursor);
				_cursor = null;
			}
		}
	}

	/**
	 * Called by the internal game loop to update the mouse pointer's position in the game world.
	 * Also updates the just pressed/just released flags.
	 * @param X The current X position of the mouse in the window.
	 * @param Y The current Y position of the mouse in the window.
	 */
	public function update():Void
	{
		var X = Math.floor(FlxG._game.mouseX);
		var Y = Math.floor(FlxG._game.mouseY);
		
		_globalScreenPosition.x = X;
		_globalScreenPosition.y = Y;
		updateCursor();
		if ((_last == -1) && (_current == -1))
		{
			_current = 0;
		}
		else if ((_last == 2) && (_current == 2))
		{
			_current = 1;
		}
		else if ((_last == -2) && (_current == -2))
		{
			_current = 0;
		}
		_last = _current;
	}

	/**
	 * Internal function for helping to update the mouse cursor and world coordinates.
	 */
	private function updateCursor():Void
	{
		//actually position the flixel mouse cursor graphic
		if (_updateCursorContainer)
		{
			cursorContainer.x = _globalScreenPosition.x;
			cursorContainer.y = _globalScreenPosition.y;
		}
		
		//update the x, y, screenX, and screenY variables based on the default camera.
		//This is basically a combination of getWorldPosition() and getScreenPosition()
		var camera:FlxCamera = FlxG.camera;
		screenX = Math.floor((_globalScreenPosition.x - camera.x)/camera.zoom);
		screenY = Math.floor((_globalScreenPosition.y - camera.y)/camera.zoom);
		x = screenX + camera.scroll.x;
		y = screenY + camera.scroll.y;
	}

	/**
	 * Fetch the world position of the mouse on any given camera.
	 * NOTE: Mouse.x and Mouse.y also store the world position of the mouse cursor on the main camera.
	 * @param Camera If unspecified, first/main global camera is used instead.
	 * @param point An existing point object to store the results (if you don't want a new one created).
	 * @return The mouse's location in world space.
	 */
	public function getWorldPosition(Camera:FlxCamera = null, point:FlxPoint = null):FlxPoint
	{
		if (Camera == null)
		{
			Camera = FlxG.camera;
		}
		if (point == null)
		{
			point = new FlxPoint();
		}
		getScreenPosition(Camera,_point);
		point.x = _point.x + Camera.scroll.x;
		point.y = _point.y + Camera.scroll.y;
		return point;
	}

	/**
	 * Fetch the screen position of the mouse on any given camera.
	 * NOTE: Mouse.screenX and Mouse.screenY also store the screen position of the mouse cursor on the main camera.
	 * @param Camera If unspecified, first/main global camera is used instead.
	 * @param point An existing point object to store the results (if you don't want a new one created).
	 * @return The mouse's location in screen space.
	 */
	public function getScreenPosition(Camera:FlxCamera = null, point:FlxPoint = null):FlxPoint
	{
		if (Camera == null)
		{
			Camera = FlxG.camera;
		}
		if (point == null)
		{
			point = new FlxPoint();
		}
		point.x = (_globalScreenPosition.x - Camera.x)/Camera.zoom;
		point.y = (_globalScreenPosition.y - Camera.y)/Camera.zoom;
		return point;
	}

	/**
	 * Resets the just pressed/just released flags and sets mouse to not pressed.
	 */
	public function reset():Void
	{
		_current = 0;
		_last = 0;
	}

	/**
	 * Check to see if the mouse is pressed.
	 * @return Whether the mouse is pressed.
	 */
	public function pressed():Bool { return _current > 0; }

	/**
	 * Check to see if the mouse was just pressed.
	 * @return Whether the mouse was just pressed.
	 */
	public function justPressed():Bool { return (_current == 2 || _current == -2); }

	/**
	 * Check to see if the mouse was just released.
	 * @return Whether the mouse was just released.
	 */
	public function justReleased():Bool { return (_current == -1 || _current == -2); }

	#if (FLX_MOUSE_ADVANCED && !js)
	/**
	 * Check to see if the right mouse button is pressed.
	 * Requires the <code>FLX_MOUSE_ADVANCED</code> flag in the .nmml to be set.
	 * @return Whether the right mouse button is pressed.
	 */
	public function pressedRight():Bool { return _currentRight > 0; }

	/**
	 * Check to see if the right mouse button was just pressed.
	 * Requires the <code>FLX_MOUSE_ADVANCED</code> flag in the .nmml to be set.
	 * @return Whether the right mouse button was just pressed.
	 */
	public function justPressedRight():Bool { return (_currentRight == 2 || _currentRight == -2); }

	/**
	 * Check to see if the right mouse button was just released.
	 * Requires the <code>FLX_MOUSE_ADVANCED</code> flag in the .nmml to be set.
	 * @return Whether the right mouse button was just released.
	 */
	public function justReleasedRight():Bool { return (_currentRight == -1 || _currentRight == -2); }

	/**
	 * Check to see if the middle mouse button is pressed.
	 * Requires the <code>FLX_MOUSE_ADVANCED</code> flag in the .nmml to be set.
	 * @return Whether the middle mouse button is pressed.
	 */
	public function pressedMiddle():Bool { return _currentMiddle > 0; }

	/**
	 * Check to see if the middle mouse button was just pressed.
	 * Requires the <code>FLX_MOUSE_ADVANCED</code> flag in the .nmml to be set.
	 * @return Whether the middle mouse button was just pressed.
	 */
	public function justPressedMiddle():Bool { return (_currentMiddle == 2 || _currentMiddle == -2); }

	/**
	 * Check to see if the middle mouse button was just released.
	 * Requires the <code>FLX_MOUSE_ADVANCED</code> flag in the .nmml to be set.
	 * @return Whether the middle mouse button was just released.
	 */
	public function justReleasedMiddle ():Bool { return (_currentMiddle == -1 || _currentMiddle == -2); }
	#end

	/**
	 * If the mouse changed state or is pressed, return that info now
	 * @return An array of key state data. Null if there is no data.
	 */
	public function record():MouseRecord
	{
		if ((_lastX == _globalScreenPosition.x) && (_lastY == _globalScreenPosition.y) && (_current == 0) && (_lastWheel == wheel))
		{
			return null;
		}
		_lastX = Math.floor(_globalScreenPosition.x);
		_lastY = Math.floor(_globalScreenPosition.y);
		_lastWheel = wheel;
		return new MouseRecord(_lastX,_lastY,_current,_lastWheel);
	}

	/**
	 * Part of the keystroke recording system.
	 * Takes data about key presses and sets it into array.
	 * @param KeyStates Array of data about key states.
	 */
	public function playback(Record:MouseRecord):Void
	{
		_current = Record.button;
		wheel = Record.wheel;
		_globalScreenPosition.x = Record.x;
		_globalScreenPosition.y = Record.y;
		updateCursor();
	}

	public function onFocus( ):Void
	{
		#if !FLX_NO_DEBUG
		if (!FlxG._game._debuggerUp && !useSystemCursor)
		#else
		if (!useSystemCursor)
		#end
		{
			Mouse.hide();
		}
		reset();
	}

	public function onFocusLost( ):Void
	{
		Mouse.show();
	}

	private function set_useSystemCursor(value:Bool):Bool
	{
		useSystemCursor = value;
		if (!useSystemCursor)
		{
			Mouse.hide();
		} 
		else 
		{
			Mouse.show();
		}
		return value;
	}
}