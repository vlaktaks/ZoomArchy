# ZoomArchy Plugin for Omarchy
# Zoom application with super+z shortcut and flashlight effect

QT += quick widgets

TEMPLATE = app
TARGET = ZoomArchy
CONFIG -= debug_and_release
CONFIG += c++17

# Project includes
SOURCES += main.cpp zoomarchy.cpp

RESOURCES += assets.qrc

HEADERS += ZoomArchyConfig.h zoomarchy.h

# Omarchy plugin integration
QMAKE_CXXFLAGS += -D__OMARCHY_PLUGIN__
