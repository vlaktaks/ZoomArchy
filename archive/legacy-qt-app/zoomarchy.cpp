#include "zoomarchy.h"
#include "ZoomArchyConfig.h"
#include <QKeyEvent>
#include <QMouseEvent>
#include <QDebug>

ZoomArchyApp::ZoomArchyApp(int &argc, char* argv[])
    : QGuiApplication(argc, argv)
{
}

void ZoomArchyApp::setZoomActive(bool active) {
    if (m_zoomActive == active) return;
    m_zoomActive = active;
    emit zoomActiveChanged(active);
}

void ZoomArchyApp::handleKey(QKeyEvent* event) {
    if (event->key() == Qt::Key_Z && !event->isAutoRepeat() &&
        ((event->modifiers() & Qt::MetaModifier) || (event->modifiers() & Qt::ControlModifier))) {
        bool newActive = !m_zoomActive;
        setZoomActive(newActive);
        if (!event->isAccepted()) {
            event->accept();
        }
        return;
    }
}

bool ZoomArchyApp::eventFilter(QObject *obj, QEvent *event) {
    if (event->type() == QEvent::KeyPress) {
        QKeyEvent *keyEvent = static_cast<QKeyEvent*>(event);
        // Only process and consume our shortcut keys, let others pass through
        if (keyEvent->key() == Qt::Key_Z && !keyEvent->isAutoRepeat() &&
            ((keyEvent->modifiers() & Qt::MetaModifier) || (keyEvent->modifiers() & Qt::ControlModifier))) {
            handleKey(keyEvent);
            return true; // Consume the shortcut
        }
    }
    return QGuiApplication::eventFilter(obj, event);
}