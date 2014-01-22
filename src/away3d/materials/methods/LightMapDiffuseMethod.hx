package away3d.materials.methods;

	//import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;

	import flash.display.BlendMode;
	
	//use namespace arcane;

	/**
	 * LightMapDiffuseMethod provides a diffuse shading method that uses a light map to modulate the calculated diffuse
	 * lighting. It is different from LightMapMethod in that the latter modulates the entire calculated pixel color, rather
	 * than only the diffuse lighting value.
	 */
	class LightMapDiffuseMethod extends CompositeDiffuseMethod
	{
		/**
		 * Indicates the light map should be multiplied with the calculated shading result.
		 * This can be used to add pre-calculated shadows or occlusion.
		 */
		public static var MULTIPLY:String = "multiply";

		/**
		 * Indicates the light map should be added into the calculated shading result.
		 * This can be used to add pre-calculated lighting or global illumination.
		 */
		public static var ADD:String = "add";
		
		var _texture:Texture2DBase;
		var _blendMode:String;
		var _useSecondaryUV:Bool;

		/**
		 * Creates a new LightMapDiffuseMethod method.
		 * @param lightMap The texture containing the light map.
		 * @param blendMode The blend mode with which the light map should be applied to the lighting result.
		 * @param useSecondaryUV Indicates whether the secondary UV set should be used to map the light map.
		 * @param baseMethod The diffuse method used to calculate the regular light-based lighting.
		 */
		public function new(lightMap:Texture2DBase, blendMode:String = "multiply", useSecondaryUV:Bool = false, baseMethod:BasicDiffuseMethod = null)
		{
			super(null, baseMethod);
			_useSecondaryUV = useSecondaryUV;
			_texture = lightMap;
			this.blendMode = blendMode;
		}

		/**
		 * @inheritDoc
		 */
		override public function initVO(vo:MethodVO):Void
		{
			vo.needsSecondaryUV = _useSecondaryUV;
			vo.needsUV = !_useSecondaryUV;
		}

		/**
		 * The blend mode with which the light map should be applied to the lighting result.
		 *
		 * @see LightMapDiffuseMethod.ADD
		 * @see LightMapDiffuseMethod.MULTIPLY
		 */
		public var blendMode(get, set) : BlendMode;
		public function get_blendMode() : BlendMode
		{
			return _blendMode;
		}
		
		public function set_blendMode(value:BlendMode) : BlendMode
		{
			if (value != BlendMode.ADD && value != BlendMode.MULTIPLY)
				throw new Error("Unknown blendmode!");
			if (_blendMode == value)
				return value;
			_blendMode = value;
			invalidateShaderProgram();

			return value;
		}

		/**
		 * The texture containing the light map data.
		 */
		public var lightMapTexture(get, set) : Texture2DBase;
		public function get_lightMapTexture() : Texture2DBase
		{
			return _texture;
		}
		
		public function set_lightMapTexture(value:Texture2DBase) : Texture2DBase
		{
			_texture = value;
		}

		/**
		 * @inheritDoc
		 */
		override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			stage3DProxy._context3D.setTextureAt(vo.secondaryTexturesIndex, _texture.getTextureForStage3D(stage3DProxy));
			super.activate(vo, stage3DProxy);
		}

		/**
		 * @inheritDoc
		 */
		override function getFragmentPostLightingCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var code:String;
			var lightMapReg:ShaderRegisterElement = regCache.getFreeTextureReg();
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			vo.secondaryTexturesIndex = lightMapReg.index;
			
			code = getTex2DSampleCode(vo, temp, lightMapReg, _texture, _sharedRegisters.secondaryUVVarying);
			
			switch (_blendMode) {
				case MULTIPLY:
					code += "mul " + _totalLightColorReg + ", " + _totalLightColorReg + ", " + temp + "\n";
					break;
				case ADD:
					code += "add " + _totalLightColorReg + ", " + _totalLightColorReg + ", " + temp + "\n";
					break;
			}
			
			code += super.getFragmentPostLightingCode(vo, regCache, targetReg);
			
			return code;
		}
	}
