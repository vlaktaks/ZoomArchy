#ifndef ZOOMARCHY_H
#define ZOOMARCHY_H

#include <QApplication>
#include <QGuiApplication>
#include <QQuickWindow>
#include <QQmlApplicationEngine>

class ZoomArchyApp : public QGuiApplication {
    Q_OBJECT
    
    Q_PROPERTY(bool zoomActive READ zoomActive WRITE setZoomActive NOTIFY zoomActiveChanged)
    
    public:
        explicit ZoomArchyApp(int &argc, char* argv[]);
        
        bool zoomActive() const { return m_zoomActive; }
        void setZoomActive(bool active);
    
    signals:
        void zoomActiveChanged(bool active);
    
    public slots:
        void handleKey(QKeyEvent* event);
    
    protected:
        bool eventFilter(QObject *obj, QEvent *event) override;
    
    private:
        bool m_zoomActive = false;
};

#endif // ZOOMARCHY_H