package dragonBones
{
	import dragonBones.core.DBObject;
	import dragonBones.display.IDisplayBridge;
	import dragonBones.objects.DisplayData;

	import loom2d.math.Matrix;


	public class Slot extends DBObject
	{

		public var _dislayDataList:Vector.<DisplayData>;

		public var _displayBridge:IDisplayBridge;

		public var _originZOrder:Number;

		public var _tweenZorder:Number;

		public var _isDisplayOnStage:Boolean;

		private var _isHideDisplay:Boolean;
		private var _offsetZOrder:Number;
		private var _displayIndex:int;
		private var _blendMode:String;


		public function get zOrder():Number
		{
			return _originZOrder + _tweenZorder + _offsetZOrder;
		}

		public function set zOrder(value:Number):void
		{
			if(zOrder != value)
			{
				_offsetZOrder = value - _originZOrder - _tweenZorder;
				if(this._armature)
				{
					this._armature._slotsZOrderChanged = true;
				}
			}
		}


		public function get blendMode():String {

			return _blendMode;
		}


		public function set blendMode(value:String):void {

			if(_blendMode != value){

				_blendMode = value;
				if(_displayBridge.display){

					_displayBridge.updateBlendMode(_blendMode);
				}
			}
		}



		/**
		 * The DisplayObject belonging to this Bone instance. Instance type of this object varies from flash.display.DisplayObject to startling.display.DisplayObject and subclasses.
		 */
		public function get display():Object
		{
			var displayOb:Object = _displayList[_displayIndex];
			if(displayOb is Armature)
			{
				return Armature(displayOb).display;
			}
			return displayOb;
		}

		public function set display(value:Object):void
		{
			_displayList[_displayIndex] = value;
			setDisplay(value);
		}

		/**
		 * The sub-armature of this Slot instance.
		 */
		public function get childArmature():Armature
		{
			if(_displayList[_displayIndex] is Armature){

				return _displayList[_displayIndex] as Armature;
			}

			return null;
		}


		public function set childArmature(value:Armature):void
		{
			_displayList[_displayIndex] = value;
			if(value)
			{
				setDisplay(value.display);
			}
		}

		private var _displayList:Vector.<Object>;
		/**
		 * The DisplayObject list belonging to this Slot instance.
		 */
		public function get displayList():Vector.<Object> {
			return _displayList;
		}


		public function set displayList(value:Vector.<Object>):void
		{
			if(!value) {
			//	throw new ArgumentError();
			}
			var _:int = _displayList.length = value.length;
			var i = int(_);
			while(i --)
			{
				_displayList[i] = value[i];
			}

			if(_displayIndex >= 0)
			{
				var displayIndexBackup:int = _displayIndex;
				_displayIndex = -1;
				changeDisplay(displayIndexBackup);
			}
		}

		private function setDisplay(display:Object):void
		{
			if(_displayBridge.display)
			{
				_displayBridge.display = display;
			}
			else
			{
				_displayBridge.display = display;
				if(this._armature)
				{
					_displayBridge.addDisplay(this._armature.display);
					this._armature._slotsZOrderChanged = true;
				}
			}

			updateChildArmatureAnimation();

			if(!_isHideDisplay && _displayBridge.display)
			{
				_isDisplayOnStage = true;
				_displayBridge.updateBlendMode(_blendMode);
			}
			else
			{
				_isDisplayOnStage = false;
			}
		}

		/** @private */
		public function changeDisplay(displayIndex:int):void
		{

			if(displayIndex < 0)
			{
				if(!_isHideDisplay)
				{
					_isHideDisplay = true;
					_displayBridge.removeDisplay();
					updateChildArmatureAnimation();
				}
			}
			else
			{
				if(_isHideDisplay)
				{
					_isHideDisplay = false;
					var changeShowState:Boolean = true;
					if(this._armature)
					{
						_displayBridge.addDisplay(this._armature.display);
						this._armature._slotsZOrderChanged = true;
					}
				}

				var length:uint = _displayList.length;
				if(displayIndex >= length && length > 0)
				{
					displayIndex = length - 1;
				}
				if(_displayIndex != displayIndex)
				{
					_displayIndex = displayIndex;

					var content:Object = _displayList[_displayIndex];
					if(content is Armature)
					{
						setDisplay((content as Armature).display);
					}
					else
					{
						setDisplay(content);
					}

					if(_dislayDataList && _displayIndex <= _dislayDataList.length)
						this._origin.copy(_dislayDataList[_displayIndex].transform);
				}
				else if(changeShowState)
				{
					updateChildArmatureAnimation();
				}
			}

			if(!_isHideDisplay && _displayBridge.display)
			{
				_isDisplayOnStage = true;
			}
			else
			{
				_isDisplayOnStage = false;
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function set visible(value:Boolean):void
		{
			if(value != this._visible)
			{
				this._visible = value;
				updateVisible(this._visible);
			}
		}

		/** @private */
		override public function setArmature(value:Armature):void
		{
			super.setArmature(value);
			if(this._armature)
			{
				this._armature._slotsZOrderChanged = true;
				_displayBridge.addDisplay(this._armature.display);
			}
			else
			{
				_displayBridge.removeDisplay();
			}
		}

		public function Slot(displayBrideg:IDisplayBridge)
		{
			super();
			_displayBridge = displayBrideg;
			_displayList = [];
			_displayIndex = -1;
			_scaleType = 1;

			_originZOrder = 0;
			_tweenZorder = 0;
			_offsetZOrder = 0;

			_isDisplayOnStage = false;
			_isHideDisplay = false;

			_blendMode = 'normal';
			if(_displayBridge.display){
				_displayBridge.updateBlendMode(_blendMode);
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			if(!_displayBridge)
			{
				return;
			}
			super.dispose();

			_displayBridge.dispose();
			_displayList.clear();

			_displayBridge = null;
			_displayList = null;
			_dislayDataList = null;
		}

		/** @private */
		override public function update():void
		{
			super.update();

			if(_isDisplayOnStage)
			{
				var pivotX:Number = _parent._tweenPivot.x;
				var pivotY:Number = _parent._tweenPivot.y;

				if(pivotX || pivotY)
				{

					var parentMatrix:Matrix = _parent._globalTransformMatrix;
					this._globalTransformMatrix.tx += parentMatrix.a * pivotX + parentMatrix.c * pivotY;
					this._globalTransformMatrix.ty += parentMatrix.b * pivotX + parentMatrix.d * pivotY;

				}
				_displayBridge.updateTransform(this._globalTransformMatrix, this._global);
			}
		}

		/** @private */
		public function updateVisible(value:Boolean):void
		{
			_displayBridge.visible = this._parent.visible && this._visible && value;
		}

		private function updateChildArmatureAnimation():void
		{
			var childArmature:Armature = this.childArmature;

			if(childArmature)
			{
				if(_isHideDisplay)
				{
					childArmature.animation.stop();
					childArmature.animation._lastAnimationState = null;
				}
				else
				{
					if(
						this._armature &&
						this._armature.animation.lastAnimationState &&
						childArmature.animation.hasAnimation(this._armature.animation.lastAnimationState.name)
					)
					{
						childArmature.animation.gotoAndPlay(this._armature.animation.lastAnimationState.name);
					}
					else
					{
						childArmature.animation.play();
					}
				}
			}
		}

		/**
		 * Change all DisplayObject attached to this Bone instance.
		 * @param	displayList An array of valid DisplayObject to attach to this Bone.
		 */
		public function changeDisplayList(displayList:Vector.<Object>):void
		{
			this.displayList = displayList;
		}
	}
}