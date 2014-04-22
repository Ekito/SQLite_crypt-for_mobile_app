package fr.ekito.crypteddbapp.app;

import android.database.Cursor;
import android.os.Bundle;
import android.support.v7.app.ActionBarActivity;

import net.sqlcipher.database.SQLiteDatabase;

public class MainActivity extends ActionBarActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        sampleGetDataFromDatabase();
    }

    private void sampleGetDataFromDatabase(){

        try {
            PlainDatabaseHelper db = new PlainDatabaseHelper(this,"mybase_plain.sqlite3");
            db.createDatabase();
            Cursor cursor = db.getTable();
            int count = cursor.getCount();
            System.out.println("Success!  Results returned: " + count);
        }
        catch (Exception ex){
            System.out.println("Ruh roh.  " + ex.getMessage());
        }

        try {
            SQLiteDatabase.loadLibs(this);
            EncryptedDatabaseHelper db = new EncryptedDatabaseHelper(this,"mybase_crypted.sqlite3", "0d0963db50a4503ace7ff0d915ad5b87");
            db.createDatabase();
            Cursor cursor = db.getTable();
            int count = cursor.getCount();
            System.out.println("Success!  Results returned: " + count);
        }
        catch (Exception ex){
            System.out.println("Ruh roh.  " + ex.getMessage());
        }
    }

}
