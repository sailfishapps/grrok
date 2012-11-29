#include <QApplication>
#include <QDir>
#include <QDeclarativeEngine>
#include <QDeclarativeComponent>
#include <QDeclarativeContext>
#include <QDeclarativeView>
#include <QDeclarativeItem>
#include <QDesktopWidget>
#include <QDebug>

#ifdef HAS_BOOSTER
#include <MDeclarativeCache>
#endif

#ifdef DESKTOP
#include <QGLWidget>
#endif

Q_DECL_EXPORT int main(int argc, char *argv[])
{
#ifdef HAS_BOOSTER
    QScopedPointer<QApplication> app(MDeclarativeCache::qApplication(argc, argv));
    QScopedPointer<QDeclarativeView> view(MDeclarativeCache::qDeclarativeView());
#else
    QScopedPointer<QApplication> app(new QApplication(argc, argv));
    QScopedPointer<QDeclarativeView> view(new QDeclarativeView);
#endif

#ifdef DESKTOP
    bool isDesktop = true;
    view->setViewport(new QGLWidget);
#else
    bool isDesktop = app->arguments().contains("-desktop");
#endif

    QString path("/opt/grrok/"); //default install
    qDebug() << app->applicationDirPath() + QDir::separator() + "qml/grrok/main.qml";
    if (isDesktop || QFile::exists(app->applicationDirPath() + QDir::separator() + "qml/grrok/main.qml")) {
        path = app->applicationDirPath() + QDir::separator();
    }

    view->setSource(path + QLatin1String("qml/grrok/main.qml"));

    if (view->status() == QDeclarativeView::Error) {
        qWarning() << "Unable to read main qml file";
        return 1;
    }

    if (isDesktop) {
        view->setFixedSize(480, 854);
        view->rootObject()->setProperty("_desktop", true);
        view->setResizeMode(QDeclarativeView::SizeRootObjectToView);

        if (app->arguments().contains("-openInSecondScreen")) {
            QRect secondScreenRect = QApplication::desktop()->screenGeometry(1/*screenNumber*/);
            view->move(secondScreenRect.topLeft() + QPoint(100, 100));
        }

        view->show();
    } else {
        view->setAttribute(Qt::WA_OpaquePaintEvent);
        view->setAttribute(Qt::WA_NoSystemBackground);
        view->viewport()->setAttribute(Qt::WA_OpaquePaintEvent);
        view->viewport()->setAttribute(Qt::WA_NoSystemBackground);

        view->showFullScreen();
    }

    return app->exec();
}

