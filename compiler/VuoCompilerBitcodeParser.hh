﻿/**
 * @file
 * VuoCompilerBitcodeParser interface.
 *
 * @copyright Copyright © 2012–2017 Kosada Incorporated.
 * This interface description may be modified and distributed under the terms of the GNU Lesser General Public License (LGPL) version 2 or later.
 * For more information, see http://vuo.org/license.
 */

#pragma once


/**
 * A parser to extract code elements from an LLVM module.
 */
class VuoCompilerBitcodeParser
{
private:
	Module *module;

	string resolveGlobalToConst(string name);
	string getGlobalValueConstString(string name);

public:
	VuoCompilerBitcodeParser(Module *module);
	uint64_t getGlobalUInt(string name);
	string getGlobalString(string name);
	vector<string> getStringsFromGlobalArray(string name);
	Function * getFunction(string name);
	string getArgumentNameInSourceCode(string argumentNameInBitcode);
	bool isFirstOfTwoLoweredArguments(Argument *firstArgument);
	vector<pair<Argument *, string> > getAnnotatedArguments(Function *function);
};
