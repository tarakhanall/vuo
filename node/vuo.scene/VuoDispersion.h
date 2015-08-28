/**
 * @file
 * VuoDispersion C type definition.
 *
 * @copyright Copyright © 2012–2014 Kosada Incorporated.
 * This code may be modified and distributed under the terms of the MIT License.
 * For more information, see http://vuo.org/license.
 */

#ifndef VUODISPERSION_H
#define VUODISPERSION_H

/**
 * @ingroup VuoTypes
 * @defgroup VuoDispersion VuoDispersion
 * The pattern over which a function is applied.
 *
 * @{
 */

/**
 * The pattern over which a function is applied.
 */
typedef enum {
	VuoDispersion_Linear,
	VuoDispersion_Radial
} VuoDispersion;

VuoDispersion VuoDispersion_valueFromJson(struct json_object * js);
struct json_object * VuoDispersion_jsonFromValue(const VuoDispersion value);
char * VuoDispersion_summaryFromValue(const VuoDispersion value);

/**
 * Automatically generated function.
 */
///@{
VuoDispersion VuoDispersion_valueFromString(const char *str);
char * VuoDispersion_stringFromValue(const VuoDispersion value);
void VuoDispersion_retain(VuoDispersion value);
void VuoDispersion_release(VuoDispersion value);
///@}

/**
 * @}
 */

#endif // VUODISPERSION_H