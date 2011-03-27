package com.craigshaw.playbook.view
{
	import caurina.transitions.Tweener;
	
	import com.craigshaw.playbook.view.ViewManagerTransition;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	import qnx.ui.core.Container;
	import qnx.ui.core.IContainable;

	/**
	 * Utility class for managing views 
	 * @author craigs
	 * 
	 */	
	public class ViewManager
	{
		private const In:String = "in";
		private const Out:String = "out";
		
		private var _views:Object = {};						// Map of view names to views
		private var _viewContainer:DisplayObjectContainer;	// Reference to the outer container to which the managed views will be added/removed
		private var _currentView:DisplayObjectContainer;	// Reference to the current managed view that is on the display
		private var _containerWidth:int;					// Width of the container that our views will reside in
		private var _containerHeight:int;					// Height of the container that our views will reside in
		
		/**
		 * Constructor. Creates a new instance the manages the views that can be selected within the given DisplayObjectContainer 
		 * @param viewContainer The 'parent' DisplayObjectContainer. The views managed will be added / removed to this container
		 * 
		 */		
		public function ViewManager(viewContainer:DisplayObjectContainer)
		{
			if( viewContainer == null )
				throw new Error("viewContainer cannot be null");
			
			this._viewContainer = viewContainer;
		}
		
		/**
		 * Sets the dimensions of the container that is to be managed by this ViewManager. This is required as the width and height of the 
		 * managed container can not be guaranteed to be correct at the time at which the view manager needs them. This makes things explicit 
		 * @param width Width of the view being managed
		 * @param height Height of the view being managed
		 * 
		 */		
		public function setContainerSize(width:int, height:int):void
		{
			this._containerWidth = width;
			this._containerHeight = height;
		}
		
		/**
		 * Registers a view with the manager by the given name 
		 * @param viewName A unique name for the view
		 * @param viewClass The Class reference of the view
		 * 
		 */		
		public function registerView(viewName:String, viewClass:Class):void
		{
			if( !(viewName in _views) )
				_views[viewName] = viewClass;
		}
		
		/**
		 * Switched to the named view. If viewData is also passed, this is passed through to the view being switched to if it is of a supported type 
		 * @param viewName Name of the view to switch to
		 * @param viewData Optional. View data that will be passed through to the view if the named view implements IDataView
		 * @return true if the view was found and switched to, false otherwise
		 * 
		 */		
		public function switchView(viewName:String, viewData:Object=null):Boolean
		{
			if( viewName in _views )
			{
				// Remove any existing
				if(_currentView)
					_viewContainer.removeChild(_currentView);
				
				// Create new
				var uiClass : Class = Class(_views[viewName]);
				_currentView = new uiClass();
				
				// Set data if needs be
				if(viewData && _currentView is IDataView)
					IDataView(_currentView).viewData = viewData;
				
				// Add to the display list
				_viewContainer.addChild(_currentView);
				
				// Remember to size the new view
				if(_currentView is IContainable)
					IContainable(_currentView).setSize(this._containerWidth, this._containerHeight);
				
				return true;
			}
			
			return false;
		}
		
		/**
		 * Provides a simple full screen view switching mechanism using a tween to animate to the new view. 
		 * Creates the named view (if available), supplies it with the viewData (if available)
		 * and then adds it to the display list. Also removes any current view from the display list 
		 * TODO: We should probably make this a little more defensive. So if a switch is triggered whilst a previous tween is active,
		 * we clean up first. It shouldn't be an issue now I've made the transition 250ms but it would be slicker to fix it. Next version though!
		 * 
		 * @param viewName The name of the view to display
   * @param transition The name of the transition to apply when switching views. Available transitions defined in ViewManagerTransition
		 * @param viewData Optional. View data that will be passed through to the view if the named view implements IDataView
   * @param duration Optional. Duration of the transition (in seconds) 
		 * @return true if the new view was created, false otherwise 
		 * 
		 */		
		public function switchViewWithTransition(viewName:String, transition:String, viewData:Object=null, duration:Number = 0.5):Boolean
		{
			if( viewName in _views)
			{
				// Create the new view
				var uiClass : Class = Class(_views[viewName]);
				var incomingView : DisplayObjectContainer = new uiClass();
				
				// Set its data if we need to
				if( viewData && incomingView is IDataView) 
					IDataView(incomingView).viewData = viewData;

				// Initialise new view for the appropriate tween
				initialiseViewForTransition(incomingView, transition);
				
				// Add it to the display list
				_viewContainer.addChild(incomingView);
				
				// Size the new view
				if(incomingView is IContainable)
					IContainable(incomingView).setSize(this._containerWidth, this._containerHeight);
				
				// Trigger the tween to move the current view out
				if(_currentView)
					Tweener.addTween(_currentView, createTweenParametersForTransition(transition, duration, Out));
				
				
				// Now tween it in
				var tweenParams:Object = createTweenParametersForTransition(transition, duration, In);
				tweenParams.onComplete = function():void
				{
					if (_currentView)
						_viewContainer.removeChild(_currentView);
					
					_currentView = incomingView;
				};
				Tweener.addTween(incomingView, tweenParams);
				
				return true;
			}
			
			return false;
		}
		
		/**
		 * Creates an object with the tween parameters for the appropriate transition 
		 * @param transition The required transition
		 * @param duration The duration of the transition
		 * @param direction The direction of the transition In or Out
		 * @return object containing tween params
		 * 
		 */		
		private function createTweenParametersForTransition(transition:String, duration:Number, direction:String):Object
		{
			var tweenParams:Object = {};
			tweenParams.time = duration;
			
			if(transition == ViewManagerTransition.FadeInOut)
				tweenParams.alpha = (direction == Out)?0:1;
			else if(transition == ViewManagerTransition.WipeLeft)
				tweenParams.x = (direction == Out)?0-this._containerWidth:0;
			else if(transition == ViewManagerTransition.WipeRight)
				tweenParams.x = (direction == Out)?this._containerWidth:0;
			else if(transition == ViewManagerTransition.WipeUp)
				tweenParams.y = (direction == Out)?0-this._containerHeight:0;
			else if(transition == ViewManagerTransition.WipeDown)
				tweenParams.y = (direction == Out)?this._containerHeight:0;
			
			return tweenParams;
		}
		
		/**
		 * Initialises the properties of the incoming view for its transition 
		 * @param incomingView The incoming view
		 * @param transition The transition required
		 * 
		 */		
		private function initialiseViewForTransition(incomingView:DisplayObjectContainer, transition:String):void
		{
			if(transition == ViewManagerTransition.FadeInOut)
				incomingView.alpha = 0;
			else if(transition == ViewManagerTransition.WipeLeft)
				incomingView.x = this._containerWidth;
			else if(transition == ViewManagerTransition.WipeRight)
				incomingView.x = 0;
			else if(transition == ViewManagerTransition.WipeUp)
				incomingView.y = this._containerHeight;
			else if(transition == ViewManagerTransition.WipeDown)
				incomingView.y = 0;
		}
		
		/**
		 * Returns a reference to the current view 
		 * @return 
		 * 
		 */		
		public function get currentView():DisplayObjectContainer
		{
			return _currentView;
		}
	}
}