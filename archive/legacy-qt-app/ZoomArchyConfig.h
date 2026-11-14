#ifndef ZOOMARCHYCONFIG_H
#define ZOOMARCHYCONFIG_H

#include <QColor>
#include <QString>

namespace ZoomArchy {

    struct Config {
        bool zoomActive = false;
        float zoomLevel = 5.0f;
        QString highlightColor = "#e74c3c";
        int minZoomDistance = 100;
        int maxZoomLevel = 20;
        
        bool showRayCursor = true;
        float rayWidth = 50.0f;
        
        bool safeMode = true;
        bool noNetworkAccess = true;
        
        bool respectTheme = true;
    };
    
}

#endif // ZOOMARCHYCONFIG_H
