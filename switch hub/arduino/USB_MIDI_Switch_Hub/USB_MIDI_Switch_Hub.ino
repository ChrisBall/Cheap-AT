//https://forum.arduino.cc/t/midi-usb-on-the-nano-esp32/1162846/7  very useful
// getting USB MIDI and BLE MIDI working concurrently is proving difficult
// have switched to the ESP32 built in USB MIDI library - 10/06/2024

#include "USB.h"
#include "USBMIDI.h"
#include <EEPROM.h>  //built in 2.0.0

#define NUM_INPUTS 8
#define EEPROM_SIZE NUM_INPUTS * 5 + 1  //5 bytes for each input's channel, note, velocity, min on time, and retrigger time; and an init flag

USBMIDI MIDI;

const int pins[NUM_INPUTS] = { 1, 2, 4, 43, 44, 7, 8, 9 };
boolean states[NUM_INPUTS] = { 0, 0, 0, 0, 0, 0, 0, 0 };

//factory defaults
const byte defaultScale[NUM_INPUTS] = { 60, 62, 64, 65, 67, 69, 71, 72 };
const byte defaultChannel[NUM_INPUTS] = { 0, 0, 0, 0, 0, 0, 0 };
const byte defaultVelocity[NUM_INPUTS] = { 64, 64, 64, 64, 64, 64, 64, 64 };
const byte defaultMinTime[NUM_INPUTS] = { 0, 0, 0, 0, 0, 0, 0 };
const byte defaultRetrigger[NUM_INPUTS] = { 0, 0, 0, 0, 0, 0, 0 };

//variables
byte scale[NUM_INPUTS] = { 60, 62, 64, 65, 67, 69, 71, 72 };
byte channel[NUM_INPUTS] = { 0, 0, 0, 0, 0, 0, 0 };
byte velocity[NUM_INPUTS] = { 64, 64, 64, 64, 64, 64, 64, 64 };
byte minTime[NUM_INPUTS] = { 0, 0, 0, 0, 0, 0, 0 };
byte retrigger[NUM_INPUTS] = { 0, 0, 0, 0, 0, 0, 0 };

const uint32_t debounceTime = 20;
uint32_t lastAction[NUM_INPUTS] = { 0, 0, 0, 0, 0, 0, 0, 0 };

void setup() {
  Serial.begin(115200);
  delay(2000);
  Serial.println("Starting...");

  for (int i = 0; i < NUM_INPUTS; i++) {
    pinMode(pins[i], INPUT_PULLUP);
    states[i] = false;
  }

  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);

  MIDI.begin();
  USB.begin();

  if (!EEPROM.begin(EEPROM_SIZE)) {
    Serial.println("failed to initialise EEPROM");
  }
  loadEEPROM();  //load values from EEPROM
}

void loop() {
  //read and act on any incoming MIDI packets
  midiEventPacket_t incoming;
  while (MIDI.readPacket(&incoming)) {   
    Serial.println("incoming midi message:");
    Serial.print(incoming.byte1);
    Serial.print('\t');
    Serial.print(incoming.byte2);
    Serial.print('\t');
    Serial.println(incoming.byte3);
    if (incoming.byte1 >> 4 == B1011) {  //if control change
      onControlChange(incoming.byte1 & B00001111, incoming.byte2, incoming.byte3);
    }
  }

  //Send any outgoing MIDI packets; also debounces - should also handle minimum ON times (not implemented)
  for (int i = 0; i < NUM_INPUTS; i++) {
    if (!digitalRead(pins[i]) && !states[i] && (millis() > (lastAction[i] + debounceTime))) {
      MIDI.noteOn(scale[i], velocity[i], channel[i]);
      states[i] = true;
      lastAction[i] = millis();
      Serial.print(i);
      Serial.println(" pressed");
    } else if (digitalRead(pins[i]) && states[i] && (millis() > (lastAction[i] + debounceTime))) {
      MIDI.noteOff(scale[i], 0, channel[i]);
      states[i] = false;
      lastAction[i] = millis();
      Serial.print(i);
      Serial.println(" released");
    }
  }
}

void loadEEPROM() {  //load any settings from EEPROM & write defaults if they have not been set
  Serial.print("loading EEPROM...");
  if (EEPROM.read(EEPROM_SIZE - 1) == 255) {  //if EEPROM has not been initialised (flag value)
    Serial.println(EEPROM.read(EEPROM_SIZE - 1));
    resetToDefaults();
  } else {
    for (int i = 0; i < NUM_INPUTS; i++) {
      scale[i] = EEPROM.read(NUM_INPUTS * 0 + i);
      channel[i] = EEPROM.read(NUM_INPUTS * 1 + i);
      velocity[i] = EEPROM.read(NUM_INPUTS * 2 + i);
      minTime[i] = EEPROM.read(NUM_INPUTS * 3 + i);
      retrigger[i] = EEPROM.read(NUM_INPUTS * 4 + i);
    }
  }
  Serial.println("OK");
}

void resetToDefaults() {  //loads factory defaults from program memory and saves to EEPROM
  Serial.println("setting to defaults");
  for (int i = 0; i < NUM_INPUTS; i++) {
    scale[i] = defaultScale[i];
    channel[i] = defaultChannel[i];
    velocity[i] = defaultVelocity[i];
    minTime[i] = defaultMinTime[i];
    retrigger[i] = defaultRetrigger[i];
  }
  saveEEPROM();
}

void saveEEPROM() {
  Serial.print("saving EEPROM...");
  //save all working variables to EEPROM
  for (int i = 0; i < NUM_INPUTS; i++) {
    EEPROM.write(NUM_INPUTS * 0 + i, scale[i]);
    EEPROM.write(NUM_INPUTS * 1 + i, channel[i]);
    EEPROM.write(NUM_INPUTS * 2 + i, velocity[i]);
    EEPROM.write(NUM_INPUTS * 3 + i, minTime[i]);
    EEPROM.write(NUM_INPUTS * 4 + i, retrigger[i]);
  }
  //write EEPROM init flag value
  EEPROM.write(EEPROM_SIZE - 1, 0);
  EEPROM.commit(); //required to ACTUALLY write
  Serial.println(EEPROM.read(EEPROM_SIZE - 1));
  Serial.println("OK");
}

//CC message handling
void onControlChange(byte midiChan, byte control, byte value) {
  Serial.print(midiChan);
  Serial.print('\t');
  Serial.print(control);
  Serial.print('\t');
  Serial.println(value);
  switch (control) {
    case (102):  //reset to defaults
      if (midiChan < NUM_INPUTS) {
        scale[midiChan] = defaultScale[midiChan];
        channel[midiChan] = defaultChannel[midiChan];
        velocity[midiChan] = defaultVelocity[midiChan];
        minTime[midiChan] = defaultMinTime[midiChan];
        retrigger[midiChan] = defaultRetrigger[midiChan];
        saveEEPROM();
      } else if (midiChan == 15) {
        resetToDefaults();
      }
      break;

    case (103):  //set output MIDI channel per switch
      if (midiChan < NUM_INPUTS) {
        channel[midiChan] = value;
        saveEEPROM();
      } else if (midiChan == 15) {
        for (int i = 0; i < NUM_INPUTS; i++) {
          channel[i] = value;
        }
        saveEEPROM();
      }
      break;

    case (104):  //set output MIDI note per switch
      if (midiChan < NUM_INPUTS) {
        scale[midiChan] = value;
        saveEEPROM();
      } else if (midiChan == 15) {
        for (int i = 0; i < NUM_INPUTS; i++) {
          scale[i] = value;
        }
        saveEEPROM();
      }
      break;

    case (105):  //set output MIDI velocity per switch
      if (midiChan < NUM_INPUTS) {
        velocity[midiChan] = value;
        saveEEPROM();
      } else if (midiChan == 15) {
        for (int i = 0; i < NUM_INPUTS; i++) {
          velocity[i] = value;
        }
        saveEEPROM();
      }
      break;

    case (106):  //set minimum on time per switch
      if (midiChan < NUM_INPUTS) {
        minTime[midiChan] = value;
        saveEEPROM();
      } else if (midiChan == 15) {
        for (int i = 0; i < NUM_INPUTS; i++) {
          minTime[i] = value;
        }
        saveEEPROM();
      }
      break;

    case (107):  //set retrigger period per switch
      if (midiChan < NUM_INPUTS) {
        retrigger[midiChan] = value;
        saveEEPROM();
      } else if (midiChan == 15) {
        for (int i = 0; i < NUM_INPUTS; i++) {
          retrigger[i] = value;
        }
        saveEEPROM();
      }
      break;

    default:
      break;
  }
}
