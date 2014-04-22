package fr.ekito.crypteddbapp.app;


import android.content.Context;
import android.util.Log;

import net.sqlcipher.Cursor;
import net.sqlcipher.SQLException;
import net.sqlcipher.database.SQLiteDatabase;
import net.sqlcipher.database.SQLiteOpenHelper;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

/**<
 * Created by arnaud on 18/04/14.
 */
public class EncryptedDatabaseHelper extends SQLiteOpenHelper {

    private String DATABASE_PWD = "";
    private SQLiteDatabase database;
    private final Context androidContext;

    private String DATABASE_NAME = "";
    private String DATABASE_PATH = "";//"/data/data/com.geekstentialism.androidwithdb/databases/";
    public static final int DATABASE_VERSION = 1;

    public EncryptedDatabaseHelper(Context context, String dbName, String password){
        super(context, dbName, null, DATABASE_VERSION);

        DATABASE_NAME = dbName;
        DATABASE_PATH = "/data/data/"+context.getPackageName()+"/databases/";
        DATABASE_PWD = password;
        this.androidContext = context;
    }

    /**
     * Creates a empty database on the system and rewrites it with your own database.
     * */
    public void createDatabase() throws IOException {

        boolean dbExist = checkDatabase();

        if(dbExist){
            //do nothing - database already exist
        }
        else {
            openDatabase();
            database.close();

            try {
                copyDatabase();
            } catch (IOException e) {
                throw new Error("Error copying database");
            }
        }
    }

    /**
     * Check if the database already exist to avoid re-copying the file each time you open the application.
     * @return true if it exists, false if it doesn't
     */
    private boolean checkDatabase(){

        boolean exists = false;

        try{
            String myPath = DATABASE_PATH + DATABASE_NAME;
            File dbFile = new File(myPath);
            exists = dbFile.exists();
        }catch(Exception e){

            //database does't exist yet.
            Log.e("DB_APP","check db error : "+e);
        }
        return exists;
    }

    /**
     * Copies your database from your local assets-folder to the just created empty database in the
     * system folder, from where it can be accessed and handled.
     * This is done by transfering bytestream.
     * */
    public void copyDatabase() throws IOException {

        //Open your local db as the input stream
        InputStream myInput = androidContext.getAssets().open(DATABASE_NAME);

        // Path to the just created empty db
        String outFileName = DATABASE_PATH + DATABASE_NAME;

        //Open the empty db as the output stream
        OutputStream myOutput = new FileOutputStream(outFileName);

        //transfer bytes from the inputfile to the outputfile
        byte[] buffer = new byte[1024];
        int length;
        while ((length = myInput.read(buffer))>0){
            myOutput.write(buffer, 0, length);
        }

        //Close the streams
        myOutput.flush();
        myOutput.close();
        myInput.close();

    }

    public void openDatabase() throws SQLException {

        //Open the database
        String myPath = DATABASE_PATH + DATABASE_NAME;
        database = SQLiteDatabase.openOrCreateDatabase(myPath, DATABASE_PWD, null);

    }

    @Override
    public synchronized void close() {

        if(database != null)
            database.close();

        super.close();

    }

    @Override
    public void onCreate(SQLiteDatabase db) {

    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        // TODO: Write routines upgrade
    }

    /**
     * Select from CONSO_EAU_CITE Table
     * @return
     */
    public Cursor getTable() {
        SQLiteDatabase db = getReadableDatabase(DATABASE_PWD);
        Cursor cursor = db.rawQuery("SELECT * FROM CONSO_EAU_CITE", null);
        return cursor;
    }
}
