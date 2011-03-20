package com.craigshaw.playbook.components
{
	import caurina.transitions.Tweener;
	
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	/**
	 * Animated label class. *must* be explicitly sized via the constructor. The idea was to make a label like the iPhone
	 * one that scrolls when text is too big to fit in it.
	 * Provides some default tweening behaviour at the moment, but this could easily be extended if needs be
	 * @author craigs
	 * 
	 */	
	public class AnimatedLabel extends Sprite
	{
		private var _innerTextField:TextField;		// The label that we're animating
		private var _scrollSpeed:int; 				// Scroll speed [pixels per second]
		private var _width:int;						// Specified width in pixels
		private var _height:int;					// Specified height in pixels
		
		/**
		 * 
		 * @param width Width of the label (pixels)
		 * @param height Height of the label (pixels)
		 * @param textFormat Optional text formatting that will be applied to the label
		 * @param scrollSpeed Scroll speed (pixels per second)
		 * 
		 */		
		public function AnimatedLabel(width:int, height:int, textFormat:TextFormat=null, scrollSpeed:int=50)
		{
			super();
			
			this._width = width;
			this._height = height;
			this._scrollSpeed = scrollSpeed;

     		// Create a mask
			var mask:Sprite = createSimpleMask(width, height);
			
			// Add it to the display list and wire it to this component
			this.addChild(mask);
			this.mask = mask;
			
			// Now create the label
			_innerTextField = new TextField();
			_innerTextField.autoSize = TextFieldAutoSize.LEFT;
			_innerTextField.x = 0;
			_innerTextField.y = 0;
			if(textFormat)
				_innerTextField.defaultTextFormat = textFormat;
			
			// Now add the label
			this.addChild(_innerTextField);
		}
		
		/**
		 * Sets the label text 
		 * @param value
		 * 
		 */		
		public function set text(value:String):void
		{
			if(_innerTextField.text != value)
			{
				// Set the text
				_innerTextField.text = value;
				
				// stop any running animations
				stopAnimation();
			}
		}
		
		/**
		 * Start the control animation if required
		 */
		public function startAnimation():void
		{
			// check if the label needs to be animated
			if(_innerTextField.textWidth > this._width)
			{
				startLabelTween();
			}
		}
		
		/**
		 * Stop any running animation on the control
		 */
		public function stopAnimation():void
		{
			// Stop any existing animation
			if( Tweener.isTweening(_innerTextField) )
			{
				Tweener.removeTweens(_innerTextField);
				
				tweenComplete(0.5);
			}
		}
		
		/**
		 * @private
		 * Creates a simple rectangular mask to clip this container's contents 
		 * @param width
		 * @param height
		 * @return 
		 * 
		 */		
		private function createSimpleMask(width:int, height:int):Sprite
		{
			var mask:Sprite = new Sprite();
			mask.graphics.clear();
			mask.graphics.beginFill(0xFFFFFF, 1);
			mask.graphics.drawRect(0, 0, width, height);
			mask.graphics.endFill();
			return mask;
		}
		
		/**
		 * @private 
		 * Kicks off the scrolling animation
		 */		
		private function startLabelTween():void
		{		
			var scrollDelta:int = this._width - _innerTextField.textWidth - 3; // The 3 is a 'fudge factor' ... just to make sure the full text is displayed
			
			_innerTextField.x = 0;
			
			Tweener.addTween(_innerTextField,
				{
					delay     : 2.5,
					x         : scrollDelta,
					time      : getScrollDurationFromDelta(Math.abs(scrollDelta)),
					transition: "linear",
					onComplete: tweenComplete
				});
		}
				
		/**
		 * @private
		 * @param delay The animation start delay - default 2.5
		 * Pauses, post animation, then kicks another animation off to reset the position of the label 
		 */		
		private function tweenComplete(delay:Number=2.5):void
		{
			// Pause ... then reset the label position
			Tweener.addTween(_innerTextField,
				{
					delay	:	delay,
					time	:	2,
					x		:	0
				});
		}
		
		/**
		 * @private
		 * Gets the duration for the scroll, given the distance the scroll is to travel, based on the configured scroll speed 
		 * @param int The delta of the scroll
		 * @return The duration over which the scroll will be active
		 * 
		 */		
		private function getScrollDurationFromDelta(delta:int):Number
		{
			return delta / _scrollSpeed;
		}
	}
}