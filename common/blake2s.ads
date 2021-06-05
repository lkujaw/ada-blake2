--  Copyright 2021 Lev Kujawski
--
--  Language: SPARK 83 subset of ISO Ada 87 (ISO/IEC 8652:1987)
--  License: See LICENSE.txt
--
--  Based upon the RFC7693 by Saarinen and Aumasson (November, 2015).

with Octets;
with Octet_Arrays;

with Quadlets;

--# inherit Octets,
--#         Octet_Arrays,
--#         Quadlets;
package BLAKE2S is
   pragma Pure;

   type T is private;

   Digest_Length_Default : constant := 32;

   subtype Digest_Index_T is Positive
     range Positive'First .. Digest_Length_Default;
   type Digest_T is array (Digest_Index_T range <>) of Octets.T;
   subtype Digest_Default_T is Digest_T (Digest_Index_T);

   Key_Length_Default : constant := 32;

   subtype Key_Index_T is Positive
     range Positive'First .. Key_Length_Default;
   type Key_T is array (Key_Index_T range <>) of Octets.T;
   subtype Key_Default_T is Key_T (Key_Index_T);

   --  Returns True when the number of octets hashed exceeds the maximum
   --  message size of BLAKE2S (>= 2 ** 64).
   function Is_Overflowed (Context : in T) return Boolean;

   function Digest_Length_Of (Context : in T) return Digest_Index_T;
   --# return Digest_Length_Of (Context);

   procedure Hash (Message       : in     Octet_Arrays.T;
                   Digest_Length : in     Digest_Index_T;
                   Digest        :    out Digest_T);
   --# derives Digest from Digest_Length,
   --#                     Message;
   --# pre Digest'First = Digest_Index_T'First and
   --#     Digest_Length <= Digest'Length;

   procedure Hash_Flex (Message       : in     Octet_Arrays.T;
                        Message_First : in     Positive;
                        Message_Last  : in     Natural;
                        Digest_Length : in     Digest_Index_T;
                        Digest        :    out Digest_T);
   --# derives Digest from Digest_Length,
   --#                     Message,
   --#                     Message_First,
   --#                     Message_Last;
   --# pre Digest'First = Digest_Index_T'First and
   --#     Digest_Length <= Digest'Length and
   --#     Message_First in Message'Range and
   --#     Message_Last <= Message'Last;

   procedure Hash_Keyed (Key           : in     Key_T;
                         Message       : in     Octet_Arrays.T;
                         Digest_Length : in     Digest_Index_T;
                         Digest        :    out Digest_T);
   --# derives Digest from Digest_Length,
   --#                     Key,
   --#                     Message;
   --# pre Digest'First = Digest_Index_T'First and
   --#     Digest_Length <= Digest'Length and
   --#     Key'Length >= 1;

   procedure Hash_Keyed_Flex (Key           : in     Key_T;
                              Key_Length    : in     Key_Index_T;
                              Message       : in     Octet_Arrays.T;
                              Message_First : in     Positive;
                              Message_Last  : in     Natural;
                              Digest_Length : in     Digest_Index_T;
                              Digest        :    out Digest_T);
   --# derives Digest from Digest_Length,
   --#                     Key,
   --#                     Key_Length,
   --#                     Message,
   --#                     Message_First,
   --#                     Message_Last;
   --# pre Digest'First = Digest_Index_T'First and
   --#     Digest_Length <= Digest'Length and
   --#     Key_Length <= Key'Length and
   --#     Message_First in Message'Range and
   --#     Message_Last <= Message'Last;

   function Initial (Digest_Length : in Digest_Index_T) return T;
   --# return Context => Digest_Length_Of (Context) = Digest_Length;

   function Initial_Keyed_Flex (Digest_Length : in Digest_Index_T;
                                Key           : in Key_T;
                                Key_Length    : in Key_Index_T) return T;
   --# pre Key_Length <= Key'Length;
   --# return Context => Digest_Length_Of (Context) = Digest_Length;

   function Initial_Keyed (Digest_Length : in Digest_Index_T;
                           Key           : in Key_T) return T;
   --# pre Key'Length >= 1;
   --# return Context =>
   --#   Context = Initial_Keyed_Flex (Digest_Length, Key, Key'Length) and
   --#   Digest_Length_Of (Context) = Digest_Length;

   --! rule off Parameter_Rule
   procedure Incorporate (Context : in out T;
                          Message : in     Octet_Arrays.T);
   --! rule on Parameter_Rule
   --# derives Context from *,
   --#                      Message;

   --! rule off Parameter_Rule
   procedure Incorporate_Flex (Context       : in out T;
                               Message       : in     Octet_Arrays.T;
                               Message_First : in     Positive;
                               Message_Last  : in     Natural);
   --! rule on Parameter_Rule
   --# derives Context from *,
   --#                      Message,
   --#                      Message_First,
   --#                      Message_Last;
   --# pre Message_First in Message'Range and
   --#     Message_Last <= Message'Last;

   procedure Finalize (Context : in out T;
                       Digest  :    out Digest_T);
   --# derives Context,
   --#         Digest  from Context;
   --# pre Digest'First = Digest_Index_T'First and
   --#     Digest'Length >= Digest_Length_Of (Context);

   type Status_T is (Success, Failure);

   function Self_Test return Status_T;

private

   subtype Hash_State_Index_T is Natural range 0 .. 7;
   type Hash_State_T is array (Hash_State_Index_T) of Quadlets.T;
   pragma Pack (Hash_State_T);
   for Hash_State_T'Size use (Hash_State_Index_T'Last + 1) * Quadlets.Bits;

   Buffer_Octets : constant := 64;

   subtype Buffer_Index_T is Natural range 0 .. Buffer_Octets - 1;
   type Buffer_T is array (Buffer_Index_T) of Octets.T;
   pragma Pack (Buffer_T);
   for Buffer_T'Size use Buffer_Octets * Octets.Bits;

   type T is
      record
         Hash_State         : Hash_State_T;
         Input_Octets_Lower : Quadlets.T;
         Input_Octets_Upper : Quadlets.T;
         Input_Buffer       : Buffer_T;
         Buffer_Index       : Natural;
         Digest_Length      : Digest_Index_T;
         Overflowed         : Boolean;
      end record;

end BLAKE2S;
