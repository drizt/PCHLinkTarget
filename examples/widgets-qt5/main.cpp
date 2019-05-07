
int main(int argc, char *argv[])
{
    QApplication a(argc, argv);

    QDialog dlg;
    dlg.show();
    dlg.setWindowTitle("Hello world!");

    return a.exec();
}
