package com.craigshaw.playbook.view
{
	/**
	 * Defines a view that can have data passed to it on a transition when managed by the ViewManager 
	 * @author craigs
	 * 
	 */	
	public interface IDataView
	{
		/**
		 * Data item for this view 
		 * @param data
		 * 
		 */		
		function set viewData(data:Object):void;
	}
}