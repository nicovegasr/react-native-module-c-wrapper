#include <gtest/gtest.h>

#include <string>

#include "CaesarCipher.h"

namespace caesar = nicovegasr::caesar;

TEST(Encrypt, ShiftsLowercaseLetters) {
  EXPECT_EQ(caesar::encrypt("abc", 3), "def");
}

TEST(Encrypt, ShiftsUppercaseLettersPreservingCase) {
  EXPECT_EQ(caesar::encrypt("AbZ", 1), "BcA");
}

TEST(Encrypt, WrapsAroundEndOfAlphabet) {
  EXPECT_EQ(caesar::encrypt("xyz", 3), "abc");
}

TEST(Encrypt, PreservesNonAlphabeticCharacters) {
  EXPECT_EQ(caesar::encrypt("hola, mundo! 123", 5), "mtqf, rzsit! 123");
}

TEST(Encrypt, NormalizesShiftGreaterThan26) {
  EXPECT_EQ(caesar::encrypt("abc", 29), "def");  // 29 % 26 == 3
}

TEST(Encrypt, SupportsNegativeShift) {
  EXPECT_EQ(caesar::encrypt("def", -3), "abc");
}

TEST(Encrypt, ZeroShiftIsIdentity) {
  EXPECT_EQ(caesar::encrypt("Hola Mundo", 0), "Hola Mundo");
}

TEST(Encrypt, EmptyStringStaysEmpty) {
  EXPECT_EQ(caesar::encrypt("", 7), "");
}

TEST(Encrypt, HandlesLongInputWithoutCorruption) {
  std::string input(10'000, 'a');
  std::string expected(10'000, 'd');
  EXPECT_EQ(caesar::encrypt(input, 3), expected);
}

TEST(Decrypt, ReversesKnownCiphertext) {
  EXPECT_EQ(caesar::decrypt("def", 3), "abc");
}

TEST(Decrypt, IsInverseOfEncryptForSampleInputs) {
  const std::string samples[] = {"", "a", "Hola, Mundo!", "XYZ xyz", "1234 !?"};
  for (const auto& sample : samples) {
    for (int shift : {-30, -1, 0, 1, 3, 25, 26, 52, 1000}) {
      EXPECT_EQ(caesar::decrypt(caesar::encrypt(sample, shift), shift), sample)
          << "sample=\"" << sample << "\" shift=" << shift;
    }
  }
}
