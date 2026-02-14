/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*) 
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file. 
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.database.library.search.textindex;

import core.sync.mutex : Mutex;
import uim.database.library;

mixin(ShowModule!());

@safe:


class TextSearchIndex {
private:
  Mutex _mutex;
  size_t[string][string] _tokenFreqByTable;

public:
  this() {
    _mutex = new Mutex;
  }

  // Simple whitespace tokenizer; can be enhanced with more complex logic if needed
  void indexText(string table, string text) {
    synchronized (_mutex) {
      tokenize(text).each!(token => _tokenFreqByTable[table][token] += 1);
    }
  }

  bool isIndexed(string table) {
    synchronized (_mutex) {
      return table in _tokenFreqByTable;
    }
  }

  bool isEmpty(string table) {
    synchronized (_mutex) {
      return !(table in _tokenFreqByTable) || _tokenFreqByTable[table].empty;
    }
  }

  // #region contains
  // Checks if all of the specified terms exist in the given table
  bool containsAllTerms(string table, string[] terms) {
    synchronized (_mutex) {
      if (table in _tokenFreqByTable) {
        auto tableMap = _tokenFreqByTable[table];
        return terms.all!(term => term in tableMap);
      }
      return false;
    }
  }
  /// 
  unittest {
    auto index = new TextSearchIndex;
    index.indexText("mytable", "hello world");
    assert(index.containsAllTerms("mytable", ["hello", "world"]) == true);
    assert(index.containsAllTerms("mytable", ["hello", "foo"]) == false);
  }

  // Checks if any of the specified terms exist in the given table
  bool containsAnyTerm(string table, string[] terms) {
    synchronized (_mutex) {
      if (table in _tokenFreqByTable) {
        auto tableMap = _tokenFreqByTable[table];
        return terms.any!(term => term in tableMap);
      }
      return false;
    }
  }
  /// 
  unittest {
    auto index = new TextSearchIndex;
    index.indexText("mytable", "hello world");
    assert(index.containsAnyTerm("mytable", ["hello", "foo"]) == true);
    assert(index.containsAnyTerm("mytable", ["foo", "bar"]) == false);
  }

  /**    
    * Checks if the specified term exists in the given table
    *
    * Params:
    *   table: The name of the table to check
    *   term: The term to look for
    *
    * Returns: true if the term exists in the table, false otherwise
    */
  bool containsTerm(string table, string term) {
    synchronized (_mutex) {
      return table in _tokenFreqByTable && term in _tokenFreqByTable[table];
    }
    ///
    unittest {
      auto index = new TextSearchIndex;
      index.indexText("mytable", "hello world");
      assert(index.containsTerm("mytable", "hello") == true);
      assert(index.containsTerm("mytable", "world") == true);
      assert(index.containsTerm("mytable", "foo") == false);
      assert(index.containsTerm("othertable", "hello") == false);
    }
  }
  // #endregion contains

  bool hasTermWithPrefix(string table, string prefix) {
    synchronized (_mutex) {
      if (table in _tokenFreqByTable) {
        auto tableMap = _tokenFreqByTable[table];
        return tableMap.keys.any!(term => term.startsWith(prefix));
      }
      return false;
    }
  }

  // #region hasTable
  bool hasAllTable(string[] tables) {
    synchronized (_mutex) {
      return tables.all!(table => table in _tokenFreqByTable);
    }
  }

  bool hasAnyTable(string[] tables) {
    synchronized (_mutex) {
      return tables.any!(table => table in _tokenFreqByTable);
    }
  }

  bool hasTable(string table) {
    synchronized (_mutex) {
      return table in _tokenFreqByTable;
    }
  }
  // #endregion hasTable

  size_t countTokenFrequency(string table, string token) {
    synchronized (_mutex) {
      return table in _tokenFreqByTable && token in _tokenFreqByTable[table] ? _tokenFreqByTable[table][token] : 0;
    }
  }

  // Returns the total number of unique tokens indexed for the specified table
  size_t countUniqueToken(string table) {
    synchronized (_mutex) {
      if (table in _tokenFreqByTable) {
        return _tokenFreqByTable[table].length;
      }
      return 0;
    }
  }

  size_t countTotalToken(string table) {
    synchronized (_mutex) {
      if (table in _tokenFreqByTable) {
        return _tokenFreqByTable[table].values.sum;
      }
      return 0;
    }
  }

  // #region search
  // Returns the count of how many times the term appears in the specified table
  Json search(string table, string term) {
    synchronized (_mutex) {
      size_t count = 0;
      if (table in _tokenFreqByTable) {
        auto tableMap = _tokenFreqByTable[table];
        if (term in tableMap) {
          count = tableMap[term];
        }
      }
      return [
        "table": Json(table),
        "term": Json(term),
        "hits": Json(cast(long)count)
      ].toJson;
    }
  }

  Json search(string table, string[] terms) {
    synchronized (_mutex) {
      size_t totalHits = 0;
      if (table in _tokenFreqByTable) {
        auto tableMap = _tokenFreqByTable[table];
        foreach (term; terms) {
          if (term in tableMap) {
            totalHits += tableMap[term];
          }
        }
      }
      return [
        "table": Json(table),
        "terms": Json(terms),
        "hits": Json(cast(long)totalHits)
      ].toJson;
    }
  }

  Json searchAll(string table) {
    synchronized (_mutex) {
      size_t totalHits = 0;
      if (table in _tokenFreqByTable) {
        auto tableMap = _tokenFreqByTable[table];
        totalHits = tableMap.values.sum;
      }
      return [
        "table": Json(table),
        "hits": Json(cast(long)totalHits)
      ].toJson;
    }
  }

  Json searchUniqueTerms(string table) {
    synchronized (_mutex) {
      size_t uniqueTerms = 0;
      if (table in _tokenFreqByTable) {
        auto tableMap = _tokenFreqByTable[table];
        uniqueTerms = tableMap.length;
      }
      return [
        "table": Json(table),
        "uniqueTerms": Json(cast(long)uniqueTerms)
      ].toJson;
    }
  }

  Json searchTermFrequencies(string table) {
    synchronized (_mutex) {
      Json result = ["table": Json(table), "terms": Json()];
      if (table in _tokenFreqByTable) {
        auto tableMap = _tokenFreqByTable[table];
        foreach (term, freq; tableMap) {
          result["terms"][term] = Json(cast(long)freq);
        }
      }
      return result.toJson;
    }
  }
  // #endregion search

private:
  string[] tokenize(string input) {
    import std.string : toLower, split;

    auto normalized = input.toLower();
    return normalized.split();
  }
}
