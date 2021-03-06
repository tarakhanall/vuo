﻿/**
 * @file
 * VuoCompilerInputDataClass implementation.
 *
 * @copyright Copyright © 2012–2020 Kosada Incorporated.
 * This code may be modified and distributed under the terms of the GNU Lesser General Public License (LGPL) version 2 or later.
 * For more information, see https://vuo.org/license.
 */

#include "VuoCompilerInputDataClass.hh"
#include "VuoCompilerInputData.hh"
#include "VuoType.hh"

/**
 * Creates a data type for a data-and-event input port.
 *
 * The default data value for instances of this data type is not set. Set it with @c setDefaultValue.
 */
VuoCompilerInputDataClass::VuoCompilerInputDataClass(string name, Type *type, bool twoParameters) :
	VuoCompilerDataClass(name, type)
{
	this->twoParameters = twoParameters;
}

/**
 * Creates a data instance based on this data type.
 */
VuoCompilerData * VuoCompilerInputDataClass::newData(void)
{
	return new VuoCompilerInputData(this);
}

/**
 * Returns the string representation of the default initial value of port data instantiated
 * from this data type.
 */
string VuoCompilerInputDataClass::getDefaultValue(void)
{
	if (details)
	{
		json_object *value = NULL;
		if (json_object_object_get_ex(details, "default", &value))
		{
			return json_object_to_json_string_ext(value, JSON_C_TO_STRING_PLAIN);
		}
		else if (json_object_object_get_ex(details, "defaults", &value))
		{
			json_object *valueForType = NULL;
			if (json_object_object_get_ex(value, getVuoType()->getModuleKey().c_str(), &valueForType))
				return json_object_to_json_string_ext(valueForType, JSON_C_TO_STRING_PLAIN);
		}
	}

	return "";
}

/**
 * Returns the string representation of @c auto value for port data instantiated
 * from this data type.
 */
string VuoCompilerInputDataClass::getAutoValue(void)
{
	if (details)
	{
		json_object *value = NULL;
		if (json_object_object_get_ex(details, "auto", &value))
			return json_object_to_json_string_ext(value, JSON_C_TO_STRING_PLAIN);
	}

	return "";
}

/**
 * Returns the boolean @c autoSupersedesDefault value for port data instantiated
 * from this data type.
 */
bool VuoCompilerInputDataClass::getAutoSupersedesDefaultValue(void)
{
	if (details)
	{
		json_object *value = NULL;
		if (json_object_object_get_ex(details, "autoSupersedesDefault", &value))
			return json_object_get_boolean(value);
	}

	return false;
}

/**
 * Returns true if, in the node event function, Clang converts this one parameter in source code
 * to two parameters in the compiled bitcode.
 */
bool VuoCompilerInputDataClass::isLoweredToTwoParameters(void)
{
	return twoParameters;
}
