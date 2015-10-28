TEMPLATE = aux
CONFIG += VuoNodeSet

include(../../vuo.pri)

GENERIC_NODE_SOURCES += \
	vuo.math.absolute.c \
	vuo.math.add.c \
	vuo.math.areEqual.c \
	vuo.math.average.c \
	vuo.math.cos.c \
	vuo.math.count.c \
	vuo.math.countWithinRange.c \
	vuo.math.exponentiate.c \
	vuo.math.fit.c \
	vuo.math.isGreaterThan.c \
	vuo.math.isLessThan.c \
	vuo.math.isWithinRange.c \
	vuo.math.keep.average.c \
	vuo.math.keep.max.c \
	vuo.math.keep.min.c \
	vuo.math.limitToRange.c \
	vuo.math.max.c \
	vuo.math.min.c \
	vuo.math.multiply.c \
	vuo.math.scale.c \
	vuo.math.sin.c \
	vuo.math.snap.c \
	vuo.math.subtract.c \
	vuo.math.tan.c

NODE_SOURCES += \
	vuo.math.calculate.c \
	vuo.math.divide.VuoInteger.c \
	vuo.math.divide.VuoReal.c \
	vuo.math.round.c \
	vuo.math.roundDown.c \
	vuo.math.roundUp.c

include(../../module.pri)
