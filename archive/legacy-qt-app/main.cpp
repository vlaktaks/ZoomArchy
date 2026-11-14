#include <QApplication>
#include <QQmlApplicationEngine>
#include <QGuiApplication>
#include <QQuickWindow>
#include <QUrl>
#include <QDebug>
#include <QQmlContext>
#include "zoomarchy.h"

int main(int argc, char *argv[]) {
    printf("Main start\n");
    ZoomArchyApp app(argc, argv);
    
    auto* engine = new QQmlApplicationEngine(nullptr);
    engine->rootContext()->setContextProperty("app", &app);
    engine->load(QUrl(QStringLiteral("qrc:/main.qml")));
    
    QGuiApplication::processEvents();
    QGuiApplication::processEvents();
    QGuiApplication::processEvents();
    
    if (engine->rootObjects().isEmpty()) {
        qWarning() << "QML load failed";
        return -1;
    }
    
    QObject *root = engine->rootObjects().first();
    QQuickWindow *window = qobject_cast<QQuickWindow*>(root);
    if (window) {
        window->installEventFilter(&app);
        window->showFullScreen();
    }
    
    // Activate zoom mode initially so UI shows zoomed view
    app.setZoomActive(true);
    
    // Prevent app from quitting when last window is closed
    QGuiApplication::setQuitOnLastWindowClosed(false);
    
    int result = app.exec();
    printf("Main end, result=%d\n", result);
    return result;
}