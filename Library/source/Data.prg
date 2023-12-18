/*
 * $Id$
 */

#include "debug.ch"
#include "vxh.ch"
#include "colors.ch"
//#include "sqlrdd.ch"

//--------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------
CLASS DataSet INHERIT Component
   PROPERTY Tables GET ::Children
   METHOD Init() CONSTRUCTOR
ENDCLASS

//--------------------------------------------------------------------------------------------------------------------------------
METHOD DataSet:Init( oOwner )
   ::__xCtrlName   := "DataSet"
   ::ClsName       := "DataSet"
   ::ComponentType := "DataSource"
   ::Super:Init( oOwner )
RETURN Self

//--------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------
CLASS DataRow
   DATA pvtColumns PROTECTED
   DATA Parent     EXPORTED

   METHOD New( Parent, nColumns ) CONSTRUCTOR
   METHOD GetRow( nIndex ) OPERATOR "[]"
   METHOD Columns INLINE ::pvtColumns[1] // NO BUG!!!
ENDCLASS

//--------------------------------------------------------------------------------------------------------------------------------
METHOD DataRow:New( Parent, aFields )
   LOCAL cField, aColumns := Array( Len( aFields ) )
   ::Parent := Parent
   FOR EACH cField IN aFields
      aColumns[ HB_EnumIndex() ] := DataColumn():New( Self, cField )
   NEXT
   ::pvtColumns := aColumns
RETURN Self

//--------------------------------------------------------------------------------------------------------------------------------
METHOD DataRow:GetRow( nIndex )
   LOCAl aColumns := ::pvtColumns
   ::Parent:FillRow( nIndex )
RETURN Self

//--------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------
CLASS DataColumn
   DATA Parent, Name, Value

   METHOD New( Parent, cName ) CONSTRUCTOR
   METHOD GetColumn( nIndex ) OPERATOR "[]"
   METHOD GetValue INLINE ::Value
   METHOD Rows     INLINE ::Parent
ENDCLASS

//--------------------------------------------------------------------------------------------------------------------------------
METHOD DataColumn:New( Parent, cName )
   ::Parent := Parent
   ::Name   := Upper( cName )
RETURN Self

//--------------------------------------------------------------------------------------------------------------------------------
METHOD DataColumn:GetColumn( xIndex )
   IF ValType( xIndex ) == 'C'
      xIndex := aScan( ::Parent:pvtColumns, {|_1| Upper( xIndex ) == _1:Name } )
   ENDIF
RETURN ::Parent:pvtColumns[ xIndex ]
